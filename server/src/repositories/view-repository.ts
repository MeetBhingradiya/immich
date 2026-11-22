import { sql, type Kysely } from 'kysely';
import { trim } from 'lodash-es';
import { InjectKysely } from 'nestjs-kysely';
import { DummyValue, GenerateSql } from 'src/decorators.js';
import { AssetVisibility } from 'src/enum.js';
import { DB } from 'src/schema/index.js';
import { asUuid, withExif } from 'src/utils/database.js';

const escapeLikePattern = (value: string) => value.replaceAll(/[\\%_]/g, String.raw`\$&`);

export class ViewRepository {
  constructor(@InjectKysely() private db: Kysely<DB>) {}

  @GenerateSql({ params: [DummyValue.UUID] })
  async getUniqueOriginalPaths(userId: string) {
    const results = await this.db
      .selectFrom('asset')
      .select(
        sql<string>`substring(replace("asset"."originalPath", '\', '/'), '^(.*/)[^/]*$')`.as('directoryPath'),
      )
      .distinct()
      .where('ownerId', '=', asUuid(userId))
      .where('visibility', '=', AssetVisibility.Timeline)
      .where('deletedAt', 'is', null)
      .where('fileCreatedAt', 'is not', null)
      .where('fileModifiedAt', 'is not', null)
      .where('localDateTime', 'is not', null)
      .orderBy('directoryPath', 'asc')
      .execute();

    return results
      .map((row) => row.directoryPath?.replace(/\/$/g, ''))
      .filter((path): path is string => Boolean(path));
  }

  @GenerateSql({ params: [DummyValue.UUID, DummyValue.STRING] })
  async getAssetsByOriginalPath(userId: string, partialPath: string) {
    const normalizedDir = (partialPath || '').replaceAll('\\', '/').replace(/\/+$/, '');
    const cleanDir =
      normalizedDir.includes(':') || normalizedDir.startsWith('/') ? normalizedDir : `/${normalizedDir}`;
    const prefix = escapeLikePattern(cleanDir ? `${cleanDir}/` : '/');

    return this.db
      .selectFrom('asset')
      .selectAll('asset')
      .$call(withExif)
      .where('ownerId', '=', asUuid(userId))
      .where('visibility', '=', AssetVisibility.Timeline)
      .where('deletedAt', 'is', null)
      .where('fileCreatedAt', 'is not', null)
      .where('fileModifiedAt', 'is not', null)
      .where('localDateTime', 'is not', null)
      .where(sql<string>`replace("asset"."originalPath", '\', '/')`, 'like', `${prefix}%`)
      .where(sql<string>`replace("asset"."originalPath", '\', '/')`, 'not like', `${prefix}%/%`)
      .orderBy(
        sql<string>`regexp_replace(replace("asset"."originalPath", '\', '/'), '.*/(.+)', '\1')`,
        'asc',
      )
      .execute();
  }
}
