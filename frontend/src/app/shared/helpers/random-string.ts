export function randomString(length = 16) {
  const pattern = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let random = '';
  for (const _element of new Array(length)) {
    random += pattern.charAt(Math.floor(Math.random() * pattern.length));
  }
  return random;
}
