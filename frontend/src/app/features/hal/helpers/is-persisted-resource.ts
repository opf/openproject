export default function isPersistedResource(resource:{id:string|null}) {
  return !!(resource.id && resource.id !== 'new');
}
