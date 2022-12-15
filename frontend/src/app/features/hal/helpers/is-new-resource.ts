export const HAL_NEW_RESOURCE_ID = 'new';

export default function isNewResource(resource:{ id:string|null }):boolean {
  return !resource.id || resource.id === HAL_NEW_RESOURCE_ID;
}
