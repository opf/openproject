import type { TFunction } from 'i18next';
import { spokenWorkPackageId } from '../../utils/id';
import { normalizeDisplay } from './display';
import type { ResolvedAttribute } from './useWorkPackageAttribute';
import { attributeIdentity, unresolvedAttributeText } from './WorkPackageAttributeView';
import type { AttributeProps } from './types';

// A long text is read where it stands, too long to be announced.
function shownText(t:TFunction, resolved:ResolvedAttribute, { attribute, display }:AttributeProps):string | undefined {
  if (resolved.state !== 'ready') return unresolvedAttributeText(t, resolved, attribute);
  if (resolved.attribute.block || normalizeDisplay(display) === 'label') return undefined;
  return resolved.value;
}

// Nothing is announced while loading, so the attribute is not announced twice.
export function describeAttribute(t:TFunction, resolved:ResolvedAttribute, content:AttributeProps):string | undefined {
  if (resolved.state === 'loading') return undefined;

  const { workPackageId, attributeName } = attributeIdentity(resolved, content.displayId, content.attribute);
  const subject = { attribute: attributeName, id: spokenWorkPackageId(t, workPackageId) };
  const value = shownText(t, resolved, content);

  return value === undefined
    ? t('workPackageAttribute.options.selectedDescription', subject)
    : t('workPackageAttribute.options.selectedValueDescription', { ...subject, value });
}
