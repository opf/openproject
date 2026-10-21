import type { PendingMode } from '../WorkPackage/types';

const pending = new Map<string, PendingMode>();

export const pendingBlockRegistry = {
  add: (blockId:string, mode:PendingMode = 'link') => pending.set(blockId, mode),
  has: (blockId:string) => pending.has(blockId),
  mode: (blockId:string) => pending.get(blockId),
  delete: (blockId:string) => pending.delete(blockId),
};
