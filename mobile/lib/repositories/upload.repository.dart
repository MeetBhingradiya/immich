import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:immich_mobile/constants/constants.dart';
import 'package:immich_mobile/domain/models/store.model.dart';
import 'package:immich_mobile/entities/store.entity.dart';
import 'package:immich_mobile/infrastructure/repositories/network.repository.dart';
import 'package:logging/logging.dart';

final uploadRepositoryProvider = Provider((ref) => UploadRepository());

class UploadRepository {
  final Logger logger = Logger('UploadRepository');
  void Function(TaskStatusUpdate)? onUploadStatus;
  void Function(TaskProgressUpdate)? onTaskProgress;

  UploadRepository() {
    FileDownloader().registerCallbacks(
      group: kBackupGroup,
      taskStatusCallback: (update) => onUploadStatus?.call(update),
      taskProgressCallback: (update) => onTaskProgress?.call(update),
    );
    FileDownloader().registerCallbacks(
      group: kBackupLivePhotoGroup,
      taskStatusCallback: (update) => onUploadStatus?.call(update),
      taskProgressCallback: (update) => onTaskProgress?.call(update),
    );
    FileDownloader().registerCallbacks(
      group: kManualUploadGroup,
      taskStatusCallback: (update) => onUploadStatus?.call(update),
      taskProgressCallback: (update) => onTaskProgress?.call(update),
    );
  }

  Future<List<bool>> enqueueBackgroundAll(List<UploadTask> tasks) {
    return FileDownloader().enqueueAll(tasks);
  }

  Future<void> deleteDatabaseRecords(String group) {
    return FileDownloader().database.deleteAllRecords(group: group);
  }

  Future<int> reset(String group) {
    return FileDownloader().reset(group: group);
  }

  /// Get a list of tasks that are ENQUEUED or RUNNING
  Future<List<Task>> getActiveTasks(String group) {
    return FileDownloader().allTasks(group: group);
  }

  Future<void> start() {
    return FileDownloader().start();
  }

  static const int kChunkSize = 50 * 1024 * 1024; // 50 MB (Cloudflare Tunnel body limit safe)

  Future<UploadResult> uploadFile({
    required File file,
    required String originalFileName,
    required Map<String, String> fields,
    required Completer<void>? cancelToken,
    void Function(int bytes, int totalBytes)? onProgress,
    required String logContext,
    Client? httpClient,
  }) async {
    // Proactively use 50MB chunked upload for any media > 50MB to guarantee Cloudflare Tunnel compatibility
    if (file.existsSync() && file.lengthSync() > kChunkSize) {
      logger.info("File $originalFileName is ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB (> 50 MB). Using Cloudflare-safe 50 MB chunked upload.");
      return uploadFileInChunks(
        file: file,
        originalFileName: originalFileName,
        fields: fields,
        cancelToken: cancelToken,
        onProgress: onProgress,
        logContext: logContext,
        httpClient: httpClient,
      );
    }

    final String savedEndpoint = Store.get(StoreKey.serverEndpoint);

    ProgressMultipartRequest buildRequest() {
      final request = ProgressMultipartRequest(
        'POST',
        Uri.parse('$savedEndpoint/assets'),
        abortTrigger: cancelToken?.future,
        onProgress: onProgress,
      );
      request.fields.addAll(fields);
      request.files.add(MultipartFile("assetData", file.openRead(), file.lengthSync(), filename: originalFileName));
      return request;
    }

    try {
      final client = httpClient ?? NetworkRepository.client;
      StreamedResponse response;
      try {
        response = await client.send(buildRequest());
      } on RequestAbortedException {
        rethrow;
      } on ClientException catch (error) {
        logger.warning("Upload $logContext failed before a response, resending once", error);
        response = await client.send(buildRequest());
      }

      final responseBodyString = await response.stream.bytesToString();

      if (![200, 201].contains(response.statusCode)) {
        String? errorMessage;

        if (response.statusCode == 413) {
          logger.info("Received HTTP 413 from reverse proxy for $logContext. Falling back to 50 MB chunked upload.");
          return uploadFileInChunks(
            file: file,
            originalFileName: originalFileName,
            fields: fields,
            cancelToken: cancelToken,
            onProgress: onProgress,
            logContext: logContext,
            httpClient: httpClient,
          );
        }

        try {
          final error = jsonDecode(responseBodyString);
          errorMessage = error['message'] ?? error['error'];
        } catch (_) {
          errorMessage = responseBodyString.isNotEmpty
              ? responseBodyString
              : 'Upload failed with status ${response.statusCode}';
        }

        return UploadResult.error(statusCode: response.statusCode, errorMessage: errorMessage);
      }

      try {
        final responseBody = jsonDecode(responseBodyString);
        return UploadResult.success(remoteAssetId: responseBody['id'] as String);
      } catch (e) {
        return UploadResult.error(errorMessage: 'Failed to parse server response');
      }
    } on RequestAbortedException {
      logger.warning("Upload $logContext was cancelled");
      return UploadResult.cancelled();
    } catch (error, stackTrace) {
      logger.warning("Error uploading $logContext", error, stackTrace);
      return UploadResult(isSuccess: false, isCancelled: false, errorMessage: error.toString(), error: error);
    }
  }

  Future<UploadResult> uploadFileInChunks({
    required File file,
    required String originalFileName,
    required Map<String, String> fields,
    required Completer<void>? cancelToken,
    void Function(int bytes, int totalBytes)? onProgress,
    required String logContext,
    Client? httpClient,
  }) async {
    final String savedEndpoint = Store.get(StoreKey.serverEndpoint);
    final int totalSize = file.lengthSync();
    final client = httpClient ?? NetworkRepository.client;

    try {
      // 1. Calculate SHA1 checksum for Repr-Digest header
      final digest = await sha1.bind(file.openRead()).first;
      final checksum = base64Encode(digest.bytes);

      // 2. Format RFC 9651 structured dictionary header
      final deviceAssetId = fields['deviceAssetId'] ?? originalFileName;
      final deviceId = fields['deviceId'] ?? 'mobile';
      final fileCreatedAt = fields['fileCreatedAt'] ?? DateTime.now().toIso8601String();
      final fileModifiedAt = fields['fileModifiedAt'] ?? DateTime.now().toIso8601String();
      final isFavorite = fields['isFavorite'] == 'true' ? ', is-favorite' : '';

      final assetData =
          'device-asset-id="$deviceAssetId", device-id="$deviceId", filename="${Uri.encodeComponent(originalFileName)}", file-created-at="$fileCreatedAt", file-modified-at="$fileModifiedAt"$isFavorite';
      final reprDigest = 'sha=:$checksum:';

      final raf = await file.open(mode: FileMode.read);
      String? remoteAssetId;

      try {
        int offset = 0;
        while (offset < totalSize) {
          if (cancelToken?.isCompleted ?? false) {
            return UploadResult.cancelled();
          }

          final int remaining = totalSize - offset;
          final int chunkSize = remaining > kChunkSize ? kChunkSize : remaining;
          await raf.setPosition(offset);
          final bytes = await raf.read(chunkSize);
          final bool isLast = (offset + chunkSize) >= totalSize;

          if (offset == 0) {
            // First chunk: POST /upload initializes session
            final request = Request('POST', Uri.parse('$savedEndpoint/upload'));
            request.headers['Content-Type'] = 'application/octet-stream';
            request.headers['Content-Length'] = chunkSize.toString();
            request.headers['Repr-Digest'] = reprDigest;
            request.headers['Upload-Draft-Interop-Version'] = '8';
            request.headers['Upload-Complete'] = isLast ? '?1' : '?0';
            request.headers['X-Immich-Asset-Data'] = assetData;
            request.bodyBytes = bytes;

            final streamedRes = await client.send(request);
            final resBody = await streamedRes.stream.bytesToString();

            if (![200, 201].contains(streamedRes.statusCode)) {
              return UploadResult.error(
                statusCode: streamedRes.statusCode,
                errorMessage: 'Chunked start upload failed: $resBody',
              );
            }

            final parsed = jsonDecode(resBody);
            remoteAssetId = parsed['id'] as String;
          } else {
            // Subsequent chunks: PATCH /upload/:id
            final request = Request('PATCH', Uri.parse('$savedEndpoint/upload/$remoteAssetId'));
            request.headers['Content-Type'] = 'application/octet-stream';
            request.headers['Content-Length'] = chunkSize.toString();
            request.headers['Upload-Offset'] = offset.toString();
            request.headers['Upload-Draft-Interop-Version'] = '8';
            request.headers['Upload-Complete'] = isLast ? '?1' : '?0';
            request.bodyBytes = bytes;

            final streamedRes = await client.send(request);
            if (![200, 201, 204].contains(streamedRes.statusCode)) {
              final resBody = await streamedRes.stream.bytesToString();
              return UploadResult.error(
                statusCode: streamedRes.statusCode,
                errorMessage: 'Chunk upload failed at offset $offset: $resBody',
              );
            }
          }

          offset += chunkSize;
          onProgress?.call(offset, totalSize);
        }

        return UploadResult.success(remoteAssetId: remoteAssetId!);
      } finally {
        await raf.close();
      }
    } catch (e, stackTrace) {
      logger.warning("Error during chunked upload of $logContext", e, stackTrace);
      return UploadResult(isSuccess: false, isCancelled: false, errorMessage: e.toString(), error: e);
    }
  }
}

class ProgressMultipartRequest extends MultipartRequest with Abortable {
  ProgressMultipartRequest(super.method, super.url, {this.abortTrigger, this.onProgress});

  @override
  final Future<void>? abortTrigger;

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) {
      return byteStream;
    }

    final total = contentLength;
    var bytes = 0;
    final stream = byteStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) {
          bytes += data.length;
          onProgress!(bytes, total);
          sink.add(data);
        },
      ),
    );
    return ByteStream(stream);
  }
}

class UploadResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? remoteAssetId;
  final String? errorMessage;
  final int? statusCode;
  final Object? error;

  const UploadResult({
    required this.isSuccess,
    required this.isCancelled,
    this.remoteAssetId,
    this.errorMessage,
    this.statusCode,
    this.error,
  });

  factory UploadResult.success({required String remoteAssetId}) {
    return UploadResult(isSuccess: true, isCancelled: false, remoteAssetId: remoteAssetId);
  }

  factory UploadResult.error({String? errorMessage, int? statusCode}) {
    return UploadResult(isSuccess: false, isCancelled: false, errorMessage: errorMessage, statusCode: statusCode);
  }

  factory UploadResult.cancelled() {
    return const UploadResult(isSuccess: false, isCancelled: true);
  }
}
