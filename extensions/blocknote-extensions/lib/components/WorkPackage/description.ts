import type { TFunction } from 'i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { formatWorkPackageId } from '../../utils/id';

export type UnavailableKind = 'unauthorized' | 'error';

export function unavailableKindOf(
  { unauthorized, error }:{ unauthorized:boolean; error:string | null },
):UnavailableKind | undefined {
  if (unauthorized) return 'unauthorized';
  if (error) return 'error';
  return undefined;
}

export function workPackageLabel(t:TFunction, displayId:string):string {
  return t('options.chipAriaLabel', { id: formatWorkPackageId(displayId) });
}

export function describeUnavailableWorkPackage(t:TFunction, displayId:string, kind:UnavailableKind):string {
  return `${workPackageLabel(t, displayId)}, ${t(`unavailableWorkPackage.${kind}.short_message`)}`;
}

// Everything a card of any size shows; nothing while the work package still loads.
export function describeLinkedWorkPackage(
  t:TFunction,
  displayId:string,
  workPackage:WorkPackage | null | undefined,
  unavailableKind:UnavailableKind | undefined,
):string | undefined {
  if (workPackage) {
    return [
      workPackageLabel(t, workPackage.displayId),
      workPackage._links?.type?.title,
      workPackage._links?.status?.title,
      workPackage.subject,
    ].filter(Boolean).join(', ');
  }
  if (unavailableKind) return describeUnavailableWorkPackage(t, displayId, unavailableKind);
  return undefined;
}
