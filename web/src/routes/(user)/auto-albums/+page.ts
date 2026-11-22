import { getAllAlbumsQuery } from '#lib/queries/album.query.ts';
import { queryClient } from '#lib/queries/client.ts';
import { authenticate } from '#lib/utils/auth.ts';
import { getAllPeople } from '@immich/sdk';
import type { PageLoad } from './$types';

export const load = (async ({ url }) => {
  await authenticate(url);
  await queryClient.query({ ...getAllAlbumsQuery(), staleTime: 0 });
  const people = await getAllPeople({ withHidden: false }).catch(() => ({ people: [], total: 0 }));

  return {
    people,
    meta: {
      title: 'Auto Albums',
    },
  };
}) satisfies PageLoad;
