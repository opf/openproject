const pending = new Set<string>();

export const pendingBlockRegistry = {
  add: (blockId: string) => pending.add(blockId),
  has: (blockId: string) => pending.has(blockId),
  delete: (blockId: string) => pending.delete(blockId),
};
