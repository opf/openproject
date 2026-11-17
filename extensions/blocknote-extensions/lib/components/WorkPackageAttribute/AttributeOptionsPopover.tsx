import { useTranslation } from 'react-i18next';
import { formatWorkPackageId } from '../../utils/id';
import { OptionsPopover } from '../Shared/OptionsMenu';
import { ATTRIBUTE_DISPLAYS, type AttributeDisplay } from './display';
import type { ResolvedAttribute } from './useWorkPackageAttribute';
import { attributeIdentity } from './WorkPackageAttributeView';

export interface AttributeOptionsPopoverProps {
  resolved:ResolvedAttribute;
  displayId:string;
  reference:string;
  active:AttributeDisplay;
  anchorEl:HTMLElement | null;
  autoFocus:boolean;
  onClose:() => void;
  onRestoreFocus:() => void;
  onPick:(display:AttributeDisplay) => void;
  onRemove:() => void;
}

export const AttributeOptionsPopover = ({
  resolved,
  displayId,
  reference,
  active,
  onPick,
  ...popoverProps
}:AttributeOptionsPopoverProps) => {
  const { t } = useTranslation();

  const { workPackageId, attributeName } = attributeIdentity(resolved, displayId, reference);
  const displayLabel = (display:AttributeDisplay) => t(`workPackageAttribute.display.${display}`);

  return (
    <OptionsPopover
      {...popoverProps}
      ariaLabel={t('workPackageAttribute.options.menuAriaLabel', { attribute: attributeName, id: formatWorkPackageId(workPackageId) })}
      openId={workPackageId}
      activeSize={active}
      sizeLabel={displayLabel(active)}
      sizeGroups={[{
        label: t('workPackageAttribute.dialog.show'),
        options: ATTRIBUTE_DISPLAYS.map((display) => ({
          key: display,
          label: displayLabel(display),
          pick: () => onPick(display),
        })),
      }]}
      removeAriaLabel={t('workPackageAttribute.options.removeAriaLabel')}
    />
  );
};
