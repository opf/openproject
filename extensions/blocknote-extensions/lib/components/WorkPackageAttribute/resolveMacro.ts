import type { WorkPackage } from '../../openProjectTypes';
import { fetchWorkPackage, isWorkPackageIdentifier, searchWorkPackages } from '../../services/openProjectApi';
import { cachedWorkPackageSchema, loadWorkPackage } from '../../services/workPackageLoader';
import { findAttribute } from './attributes';
import type { AttributeNodeKind } from './externalHtml';
import type { AttributeMacro } from './macros';
import type { AttributeChoice } from './types';

export interface ResolvedMacro {
  choice:AttributeChoice;
  kind:AttributeNodeKind;
}

// Null when the work package is not visible or has no such attribute.
export async function resolveAttributeMacro(macro:AttributeMacro):Promise<ResolvedMacro | null> {
  try {
    const id = await workPackageIdOf(macro.reference);
    if (id === undefined) return null;

    const workPackage = await loadWorkPackage(id);
    const schema = cachedWorkPackageSchema(workPackage);
    const attribute = schema && findAttribute(schema, macro.attribute);
    if (!attribute) return null;

    return {
      choice: {
        wpid: String(workPackage.id),
        displayId: workPackage.displayId,
        attribute: attribute.reference,
        display: macro.display,
      },
      kind: attribute.block ? 'block' : 'inline',
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
