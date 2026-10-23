import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { defaultWpVariables, nonSelectableStyles } from '../WorkPackage/atoms';
import { formatWorkPackageId } from '../../utils/id';
import { normalizeDisplay } from './externalHtml';
import { useWorkPackageAttribute, type ResolvedAttribute } from './useWorkPackageAttribute';

const Chip = styled.span.attrs({
  className: 'op-bn-wp-attribute',
  contentEditable: false,
})`
  ${defaultWpVariables}
  ${nonSelectableStyles}
  display: inline;
  padding: ${CHIP_STYLES.padding.s};
  border-radius: ${CHIP_STYLES.radius};
  background: ${CHIP_STYLES.bg};
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;
  cursor: pointer;
`;

const Label = styled.span<{ $muted:boolean }>`
  color: ${({ $muted }) => ($muted ? 'var(--op-wp-meta-color)' : 'var(--bn-colors-highlights-blue-text)')};
`;

const Value = styled.span`
  color: var(--bn-colors-highlights-blue-text);
  font-weight: 500;
`;

const Muted = styled.span`
  color: var(--op-wp-meta-color);
`;

interface WorkPackageAttributeChipProps {
  wpid:string;
  displayId:string;
  attribute:string;
  display:string;
}

export function WorkPackageAttributeView({ resolved, display, reference }:{
  resolved:ResolvedAttribute,
  display:string,
  reference:string,
}) {
  const { t } = useTranslation();

  if (resolved.state !== 'ready') {
    if (resolved.state === 'loading') return <Muted>{reference}…</Muted>;
    if (resolved.state === 'missing') return <Muted>{t('workPackageAttribute.missing', { attribute: reference })}</Muted>;
    return <Muted>{t(`unavailableWorkPackage.${resolved.state}.short_message`)}</Muted>;
  }

  const shown = normalizeDisplay(display);
  if (shown === 'label') return <Label $muted={false}>{resolved.attribute.label}</Label>;
  if (shown === 'value') return <Value>{resolved.value}</Value>;
  return (
    <>
      <Label $muted>{resolved.attribute.label}: </Label>
      <Value>{resolved.value}</Value>
    </>
  );
}

export function WorkPackageAttributeChip({ wpid, displayId, attribute, display }:WorkPackageAttributeChipProps) {
  const resolved = useWorkPackageAttribute(wpid, attribute);
  const title = resolved.state === 'ready'
    ? `${formatWorkPackageId(resolved.workPackage.displayId)} · ${resolved.workPackage.subject}`
    : formatWorkPackageId(displayId);

  return (
    <Chip title={title} data-drag-handle>
      <WorkPackageAttributeView resolved={resolved} display={display} reference={attribute} />
    </Chip>
  );
}
