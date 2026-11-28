<p align="center"> 
  <br/>
  <a href="https://opensource.org/license/agpl-v3"><img src="https://img.shields.io/badge/License-AGPL_v3-blue.svg?color=3F51B5&style=for-the-badge&label=License&logoColor=000000&labelColor=ececec" alt="License: AGPLv3"></a>
  <a href="https://discord.immich.app">
    <img src="https://img.shields.io/discord/979116623879368755.svg?label=Discord&logo=Discord&style=for-the-badge&logoColor=000000&labelColor=ececec" alt="Discord"/>
  </a>
  <br/>
  <br/>
</p>

<p align="center">
  <picture>
    <img
      src="design/immich-logo-stacked-light.svg"
      alt="Immich Logo"
      width="300"
    />
  </picture>
</p>
<h3 align="center">High performance self-hosted photo and video management solution</h3>
<br/>
<a href="https://immich.app">
<img src="design/immich-screenshots.png" title="Main Screenshot">
</a>
<br/>

<p align="center">
  <a href="readme_i18n/README_ca_ES.md">Català</a>
  <a href="readme_i18n/README_es_ES.md">Español</a>
  <a href="readme_i18n/README_fr_FR.md">Français</a>
  <a href="readme_i18n/README_it_IT.md">Italiano</a>
  <a href="readme_i18n/README_ja_JP.md">日本語</a>
  <a href="readme_i18n/README_ko_KR.md">한국어</a>
  <a href="readme_i18n/README_de_DE.md">Deutsch</a>
  <a href="readme_i18n/README_nl_NL.md">Nederlands</a>
  <a href="readme_i18n/README_tr_TR.md">Türkçe</a>
  <a href="readme_i18n/README_zh_CN.md">简体中文</a>
  <a href="readme_i18n/README_zh_TW.md">正體中文</a>
  <a href="readme_i18n/README_uk_UA.md">Українська</a>
  <a href="readme_i18n/README_ru_RU.md">Русский</a>
  <a href="readme_i18n/README_bg_BG.md">Български</a>
  <a href="readme_i18n/README_pl_PL.md">Polski</a>
  <a href="readme_i18n/README_pt_BR.md">Português Brasileiro</a>
  <a href="readme_i18n/README_sv_SE.md">Svenska</a>
  <a href="readme_i18n/README_ar_JO.md">العربية</a>
  <a href="readme_i18n/README_vi_VN.md">Tiếng Việt</a>
  <a href="readme_i18n/README_th_TH.md">ภาษาไทย</a>
  <a href="readme_i18n/README_ml_IN.md">മലയാളം</a>
</p>


> [!WARNING]
> ⚠️ Always follow [3-2-1](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/) backup plan for your precious photos and videos!
> 
 

> [!NOTE]
> You can find the main documentation, including installation guides, at https://immich.app/.

---

## ⚡ Meet Bhingradiya's Enterprise Fork (`MeetBhingradiya/immich`)

> **Architectural Enhancements, Zero-Knowledge Storage Encryption, Native Bare-Metal Windows Runtime & Mobile Streaming Optimization.**

This repository is a specialized production fork of [immich-app/immich](https://github.com/immich-app/immich) engineered by **[Meet Bhingradiya](https://github.com/MeetBhingradiya)**. It introduces critical enterprise security features, true zero-knowledge media storage encryption, bare-metal Windows operation without Docker or WSL2 overhead, and optimized high-performance mobile video transcoding.

---

### 🌟 Key Differences & Enhancements (Compared to Upstream Immich)

#### 1. 🔐 Zero-Knowledge Media Storage Encryption (`IMMC` AES-256-GCM)
* **At-Rest Storage Encryption:** All media files stored in the physical library (`library/`) are encrypted on disk with authenticated AES-256-GCM chunked encryption with a custom `IMMC` binary header. Even host administrators or raw disk scrapers cannot view stored photos or videos in plaintext.
* **SSO & Vault Key Escrow:** Seamless integration with production SSO vault (`/api/sso/vault`) for secure key derivation (PBKDF2/scrypt Key Encryption Keys - KEK) without storing unencrypted master keys on the local host.
* **On-the-Fly Random-Access Streaming (HTTP 206 Partial Content):** Transparent Node.js chunk-level seek pipeline (`DecryptedRangeStream`) supporting byte ranges (`Range: bytes=start-end`) directly against encrypted `IMMC` ciphertext without full-file decryption.
* **Transient Transcoding Pipeline:** Background FFmpeg jobs transiently decrypt encrypted sources into secure ephemeral scratch buffers and immediately wipe plaintext temporary files upon completion.

#### 2. 🪟 Native Bare-Metal Windows Execution (Zero-Docker / Zero-WSL2)
* **Zero Containerization Overhead:** Operates 100% natively on bare-metal Windows Server / Desktop using Bun workspaces (`bun.exe`), native PostgreSQL 14 (with `pgvector`), native Redis, and native FFmpeg binaries.
* **Native Supervisor Daemon (`start-immich-native.js`):** Self-healing orchestrator managing PostgreSQL, Redis server, native Python ML processes, and Immich microservices with automated crash recovery and PID cleanup.
* **Windows File System & Path Hardening:** Native path normalization, fcntl/POSIX fallback shims, and robust process signal handling tailored for Windows file systems.

#### 3. 🎬 Mobile Video Transcoding & Playback Optimization
* **Automated Downscaling & Codec Normalization:** Automatic downscaling of heavy 4K (3840×2160) and 1440p videos down to universally compatible 1080p/720p H.264 profiles.
* **Codec Incompatibility Fixes:** Solves Flutter/Android in-app `MediaPlayer` black screen stalls by transcoding heavy mobile formats (AV1, HEVC/H.265 50–60 Mbps iPhone recordings, ProRes `.mov`, and `.mkv` containers) into native H.264 AAC MP4.
* **Instant Start (`+faststart`):** Embeds MP4 `moov` atoms at byte 0 for instantaneous seek and stutter-free mobile streaming.

#### 4. 🧠 Native Bare-Metal Machine Learning Engine
* **Non-Docker ML Pipeline:** Completely decoupled from Docker container stacks; utilizes a dedicated native Python 3.12 virtual environment (`stack/ml-venv`) with ONNX Runtime, OpenCV, PyTorch, and InsightFace.
* **Memory Trimmer & Process Optimization:** Intelligent memory trimming and lifecycle management to prevent RAM bloat on desktop host systems while retaining full Smart Search (CLIP), Facial Recognition, and Duplicate Detection capabilities.

#### 5. 🛡️ Privacy, Security & Telemetry Cutoff
* **Zero Telemetry:** Complete network isolation of telemetry and diagnostic phone-home routines.
* **Loopback & Proxy Hardening:** Configured for internal LAN and encrypted mesh networks with explicit bypass for local endpoints.

---

## Links

- [Documentation](https://docs.immich.app/)
- [About](https://docs.immich.app/overview/introduction)
- [Installation](https://docs.immich.app/install/requirements)
- [Roadmap](https://immich.app/roadmap)
- [Demo](#demo)
- [Features](#features)
- [Translations](https://docs.immich.app/developer/translations)
- [Contributing](https://docs.immich.app/overview/support-the-project)

## Demo

Access the demo [here](https://demo.immich.app). For the mobile app, you can use `https://demo.immich.app` for the `Server Endpoint URL`.

### Login credentials

| Email           | Password |
| --------------- | -------- |
| demo@immich.app | demo     |

## Features

| Features                                     | Mobile | Web |
| :------------------------------------------- | ------ | --- |
| Upload and view videos and photos            | Yes    | Yes |
| Auto backup when the app is opened           | Yes    | N/A |
| Prevent duplication of assets                | Yes    | Yes |
| Selective album(s) for backup                | Yes    | N/A |
| Download photos and videos to local device   | Yes    | Yes |
| Multi-user support                           | Yes    | Yes |
| Album and Shared albums                      | Yes    | Yes |
| Scrubbable/draggable scrollbar               | Yes    | Yes |
| Support raw formats                          | Yes    | Yes |
| Metadata view (EXIF, map)                    | Yes    | Yes |
| Search by metadata, objects, faces, and CLIP | Yes    | Yes |
| Administrative functions (user management)   | No     | Yes |
| Background backup                            | Yes    | N/A |
| Virtual scroll                               | Yes    | Yes |
| OAuth support                                | Yes    | Yes |
| API Keys                                     | N/A    | Yes |
| LivePhoto/MotionPhoto backup and playback    | Yes    | Yes |
| Support 360 degree image display             | No     | Yes |
| User-defined storage structure               | Yes    | Yes |
| Public Sharing                               | Yes    | Yes |
| Archive and Favorites                        | Yes    | Yes |
| Global Map                                   | Yes    | Yes |
| Partner Sharing                              | Yes    | Yes |
| Facial recognition and clustering            | Yes    | Yes |
| Memories (x years ago)                       | Yes    | Yes |
| Offline support                              | Yes    | No  |
| Read-only gallery                            | Yes    | Yes |
| Stacked Photos                               | Yes    | Yes |
| Tags                                         | No     | Yes |
| Folder View                                  | Yes    | Yes |

## Translations

Read more about translations [here](https://docs.immich.app/developer/translations).

<a href="https://hosted.weblate.org/engage/immich/">
<img src="https://hosted.weblate.org/widget/immich/immich/multi-auto.svg" alt="Translation status" />
</a>

## Repository activity

![Activities](https://repobeats.axiom.co/api/embed/9e86d9dc3ddd137161f2f6d2e758d7863b1789cb.svg "Repobeats analytics image")

## Contributors

<a href="https://github.com/immich-app/immich/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=immich-app/immich" width="100%"/>
</a>
