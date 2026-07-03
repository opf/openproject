export function formatWorkPackageId(displayId:string):string {
  return /^\d+$/.test(displayId) ? `#${displayId}` : displayId;
}