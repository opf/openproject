export default function isNewResource(resource:{ id:string|null }):boolean {
  return !resource.id || resource.id === 'new';
}
