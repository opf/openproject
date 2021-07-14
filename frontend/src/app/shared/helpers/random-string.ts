const pattern = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

export function randomString(length = 16) {
  return (new Array(length))
    .fill(null)
    .map(() => pattern.charAt(Math.floor(Math.random() * pattern.length)))
    .join('');
}
