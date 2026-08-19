export default function idFromLink(href:string|null):string {
  const idPart = (href || '').split('/').pop()!.split('?')[0];
  return decodeURIComponent(idPart);
}
