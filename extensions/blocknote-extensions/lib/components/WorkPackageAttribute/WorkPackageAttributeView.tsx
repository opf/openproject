import { useTranslation } from 'react-i18next';
import { formatWorkPackageId } from '../../utils/id';
import { EMPTY_VALUE, formattedHtmlOf } from './attributes';
import { normalizeDisplay } from './externalHtml';
import type { ResolvedAttribute } from './useWorkPackageAttribute';
import {
  AttributeBlockBody,
  AttributeBlockTitle,
  AttributeLabelText,
  AttributeValueText,
  MutedText,
} from './atoms';

export function WorkPackageAttributeView({ resolved, display, reference }:{
  resolved:ResolvedAttribute,
  display:string,
  reference:string,
}) {
  const { t } = useTranslation();

  if (resolved.state !== 'ready') {
    if (resolved.state === 'loading') return <MutedText>{reference}…</MutedText>;
    if (resolved.state === 'missing') return <MutedText>{t('workPackageAttribute.missing', { attribute: reference })}</MutedText>;
    return <MutedText>{t(`unavailableWorkPackage.${resolved.state}.short_message`)}</MutedText>;
  }

  const shown = normalizeDisplay(display);
  if (shown === 'label') return <AttributeLabelText>{resolved.attribute.label}</AttributeLabelText>;
  if (shown === 'value') return <AttributeValueText>{resolved.value}</AttributeValueText>;
  return (
    <>
      <AttributeLabelText>{resolved.attribute.label}: </AttributeLabelText>
      <AttributeValueText>{resolved.value}</AttributeValueText>
    </>
  );
}

// The HTML comes rendered and sanitized by OpenProject, as its own views show it.
export function WorkPackageAttributeBlockView({ resolved, display, reference }:{
  resolved:ResolvedAttribute,
  display:string,
  reference:string,
}) {
  if (resolved.state !== 'ready') return <WorkPackageAttributeView resolved={resolved} display={display} reference={reference} />;

  const shown = normalizeDisplay(display);
  const html = formattedHtmlOf(resolved.workPackage, resolved.attribute);
  return (
    <>
      {shown !== 'value' && <AttributeBlockTitle>{resolved.attribute.label}</AttributeBlockTitle>}
      {shown !== 'label' && (html
        ? <AttributeBlockBody dangerouslySetInnerHTML={{ __html: html }} />
        : <MutedText>{EMPTY_VALUE}</MutedText>)}
    </>
  );
}

export function attributeTitle(resolved:ResolvedAttribute, displayId:string):string {
  return resolved.state === 'ready'
    ? `${formatWorkPackageId(resolved.workPackage.displayId)} · ${resolved.workPackage.subject}`
    : formatWorkPackageId(displayId);
}
