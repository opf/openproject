export default function isPersistedResource(resource:{ id:string|null }):boolean {
  return !!(resource.id && resource.id !== 'new');
}
