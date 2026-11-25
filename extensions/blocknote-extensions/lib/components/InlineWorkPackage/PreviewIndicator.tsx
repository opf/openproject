import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { InfoIcon } from '@primer/octicons-react';
import { formatWorkPackageId } from '../../utils/id';
import { useTapActivation } from '../../utils/tapActivation';
import type { WorkPackagePreview } from '../../hooks/useWorkPackagePreview';

const IndicatorButton = styled.button.attrs<{ 'data-testid'?:string }>({
  type: 'button',
  className: 'op-bn-inline-wp-preview-indicator',
  'data-testid': 'wp-preview-indicator',
})`
  appearance: none;
  background: none;
  border: 0;
  margin: 0;
  padding: 0;
  font: inherit;
  position: relative;
  top: calc((0.85em - 1cap) / 2);
  color: var(--op-wp-meta-color);
  cursor: pointer;

  svg {
    display: block;
    width: 0.85em;
    height: 0.85em;
  }

  &::after {
    content: '';
    position: absolute;
    inset: -2px -4px -2px 0;
  }
`;

export interface PreviewIndicatorProps {
  preview:WorkPackagePreview;
  displayId:string;
}

export const PreviewIndicator = ({ preview, displayId }:PreviewIndicatorProps) => {
  const { t } = useTranslation();
  const tapProps = useTapActivation();
  const indicator = preview.indicatorProps;

  if (!indicator) return null;

  const onActivation = tapProps((event) => {
    event?.preventDefault();
    event?.stopPropagation();
    indicator.toggle();
  });

  return (
    <IndicatorButton
      aria-label={t('preview.showAriaLabel', { id: formatWorkPackageId(displayId) })}
      aria-expanded={indicator.expanded}
      {...onActivation}
    >
      <InfoIcon size={12} />
    </IndicatorButton>
  );
};
