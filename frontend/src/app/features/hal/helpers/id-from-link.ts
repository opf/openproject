export default function idFromLink(href:string|null):number {
  const idPart = (href || '').split('/').pop()!;
  return parseInt(decodeURIComponent(idPart), 10);
}
