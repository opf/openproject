// Shared utilities for mngt chat controllers

export const AVATAR_PALETTE = [
  '#7c3aed', '#2563eb', '#059669', '#dc2626',
  '#d97706', '#0891b2', '#be185d', '#65a30d',
];

export function avatarColor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return AVATAR_PALETTE[Math.abs(hash) % AVATAR_PALETTE.length]!;
}

export function opAvatarUrl(streamUserId: string | undefined): string | undefined {
  const m = streamUserId?.match(/^op_(\d+)$/);
  return m ? `/users/${m[1]}/avatar` : undefined;
}
