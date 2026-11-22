import { QueryParameter } from '#lib/constants.ts';
import { queryClient } from '#lib/queries/client.ts';
import { getAssetsByOriginalPathQuery, getFolderTreeQuery } from '#lib/queries/view.query.ts';
import { authenticate } from '#lib/utils/auth.ts';
import { getFormatter } from '#lib/utils/i18n.ts';
import { TreeNode } from '#lib/utils/tree-utils.ts';
import type { PageLoad } from './$types';

export const load = (async ({ url }) => {
  await authenticate(url);
  const $t = await getFormatter();

  let root: TreeNode;
  try {
    root = await queryClient.query(getFolderTreeQuery());
  } catch (err) {
    console.error('Failed to get folder tree:', err);
    root = TreeNode.fromPaths([]);
  }

  let tree = root;
  const path = url.searchParams.get(QueryParameter.PATH);
  if (path) {
    try {
      tree = tree.traverse(path);
    } catch {
      tree = root;
    }
  } else if (path === null) {
    queryClient.removeQueries({ queryKey: ['view', 'folder', 'assets'] });
  }

  let pathAssets = null;
  if (tree.hasAssets) {
    try {
      pathAssets = await queryClient.query(getAssetsByOriginalPathQuery(tree.path));
    } catch (err) {
      console.error('Failed to get assets by path:', err);
    }
  }

  return {
    tree,
    pathAssets,
    meta: {
      title: $t('folders'),
    },
  };
}) satisfies PageLoad;

