import type { WorkPackage } from '../../openProjectTypes';
import { fetchWorkPackage, isWorkPackageIdentifier, searchWorkPackages } from '../../services/openProjectApi';
import { cachedWorkPackageSchema, loadWorkPackage } from '../../services/workPackageLoader';
import { findAttribute } from './attributes';
import type { AttributeNodeKind } from './externalHtml';
import type { AttributeMacro } from './macros';

export interface ResolvedReference {
  wpid:string;
  displayId:string;
  attribute:string;
  kind:AttributeNodeKind;
}

export function referenceKey({ reference, attribute }:AttributeMacro):string {
  return JSON.stringify([reference, attribute]);
}

// Null when the work package is not visible or has no such attribute.
export async function resolveReference({ reference, attribute }:AttributeMacro):Promise<ResolvedReference | null> {
  try {
    const id = await workPackageIdOf(reference);
    if (id === undefined) return null;

    const workPackage = await loadWorkPackage(id);
    const schema = cachedWorkPackageSchema(workPackage);
    const found = schema && findAttribute(schema, attribute);
    if (!found) return null;

    return {
      wpid: String(workPackage.id),
      displayId: workPackage.displayId,
      attribute: found.reference,
      kind: found.block ? 'block' : 'inline',
    };
  }
  catch {
    return null;
  }
}

async function workPackageIdOf(reference:string):Promise<number | undefined> {
  if (/^\d+$/.test(reference)) return Number(reference);
  if (isWorkPackageIdentifier(reference)) return (await fetchWorkPackage(reference)).id;

  return bySubject(await searchWorkPackages(reference), reference)?.id;
}

// The typeahead also matches parts of a subject, so an exact subject wins.
function bySubject(workPackages:WorkPackage[], subject:string):WorkPackage | undefined {
  const wanted = subject.trim().toLowerCase();
  return workPackages.find((workPackage) => workPackage.subject.trim().toLowerCase() === wanted)
    ?? workPackages[0];
}
