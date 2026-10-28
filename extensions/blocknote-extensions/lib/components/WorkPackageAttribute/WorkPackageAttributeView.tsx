import { Fragment } from 'react';
import { useTranslation } from 'react-i18next';
import { formatWorkPackageId } from '../../utils/id';
import { priorityColor, statusColor, typeColor } from '../../services/colors';
import { WorkPackageType } from '../WorkPackage/atoms';
import { EMPTY_VALUE, formattedHtmlOf, principalsOf, valueKindOf } from './attributes';
import { normalizeDisplay } from './externalHtml';
import type { ReadyAttribute, ResolvedAttribute } from './useWorkPackageAttribute';
import { PrincipalAvatar } from './PrincipalAvatar';
import {
  AttributeBlockBody,
  AttributeBlockTitle,
  AttributeLabelText,
  AttributeValueText,
  MutedText,
  Unbroken,
  ValueDot,
} from './atoms';

function AttributeValue({ resolved }:{ resolved:ReadyAttribute }) {
  const { workPackage, attribute, value } = resolved;
  if (value === EMPTY_VALUE) return <AttributeValueText>{value}</AttributeValueText>;

  const kind = valueKindOf(attribute);
  switch (kind) {
    case 'type':
      return <WorkPackageType as="span" $compact $color={typeColor(workPackage)}>{value}</WorkPackageType>;
    case 'status':
    case 'priority': {
      const dotColor = kind === 'status' ? statusColor(workPackage) : priorityColor(workPackage);
      return <AttributeValueText><Unbroken><ValueDot $color={dotColor} />{value}</Unbroken></AttributeValueText>;
    }
    case 'principal':
      return (
        <AttributeValueText>
          {principalsOf(workPackage, attribute).map((principal, index) => (
            // Keyed by who it is, so that another user does not inherit a loaded picture.
            <Fragment key={`${index}:${principal.href ?? principal.name}`}>
              {index > 0 && ', '}
              <Unbroken><PrincipalAvatar principal={principal} />{principal.name}</Unbroken>
            </Fragment>
          ))}
        </AttributeValueText>
      );
    default:
      return <AttributeValueText>{value}</AttributeValueText>;
  }
}

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
  if (shown === 'value') return <AttributeValue resolved={resolved} />;
  return (
    <>
      <AttributeLabelText>{resolved.attribute.label}: </AttributeLabelText>
      <AttributeValue resolved={resolved} />
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
