export function randomString(length:number = 16) {
  let pattern = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let random = '';
  for (let _element of new Array(length)) {
    random += pattern.charAt(Math.floor(Math.random() * pattern.length));
  }
  return random;
}
