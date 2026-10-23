import type { Principal } from './attributes';

// Both follow OpenProject's own avatars, so a person looks the same in the editor as elsewhere.

export function initialsOf(name:string):string {
  // Spread to iterate by code points, so an emoji is not split in half.
  const characters = [...name];
  const lastSpace = characters.lastIndexOf(' ');
  const first = characters[0]?.toUpperCase() ?? '';
  if (lastSpace === -1) return first;
  return first + (characters[lastSpace + 1]?.toUpperCase() ?? '');
}

export function avatarColorOf(principal:Principal):string {
  const id = principal.href?.split('/').pop() ?? '';
  const text = `${id}${principal.name}`;
  let hash = 0;
  for (let index = 0; index < text.length; index++) {
    hash = text.charCodeAt(index) + ((hash << 5) - hash);
  }
  return `hsl(${hash % 360}, 50%, 30%)`;
}
