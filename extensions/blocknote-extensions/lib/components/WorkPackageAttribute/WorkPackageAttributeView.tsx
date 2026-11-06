import { useTranslation } from 'react-i18next';
import { normalizeDisplay } from './externalHtml';
import type { ResolvedAttribute } from './useWorkPackageAttribute';
import { AttributeLabelText, AttributeValueText, MutedText } from './atoms';

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
