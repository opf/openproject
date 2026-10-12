import { useTranslation } from 'react-i18next';
import type { PrimerDialogComponents } from '../../services/dialogComponents';
import type { AllowedValuesSelectProps } from '../Shared/AllowedValuesSelect';
import type { AllowedValue } from '../Shared/options';

const typeLabel = ({ href, label }:AllowedValue) => (
  <span className={`__hl_uppercase __hl_foreground __hl_type_${href.split('/').pop()}`}>{label}</span>
);

export function TypeActionMenu({
  primer: { ActionList, ActionMenu }, id, label, options, value, placeholder, invalid, describedBy, onChange,
}:AllowedValuesSelectProps & { primer:PrimerDialogComponents }) {
  const { t } = useTranslation();
  const selected = options.find(option => option.href === value);
  return (
    <ActionMenu>
      <ActionMenu.Button id={id} aria-label={label} aria-invalid={invalid} aria-describedby={[`${id}-value`, describedBy].filter(Boolean).join(' ')}>
        <span id={`${id}-value`}>{selected ? typeLabel(selected) : placeholder}</span>
      </ActionMenu.Button>
      <ActionMenu.Overlay className="op-bn-picker-options op-blocknote-action-menu" maxHeight="medium" overflow="auto">
        <ActionList aria-label={label}>
          <ActionList.Group selectionVariant="single">
            {options.map(option => (
              <ActionList.Item key={option.href} selected={option.href === value} onSelect={() => onChange(option.href)}>
                {typeLabel(option)}
              </ActionList.Item>
            ))}
          </ActionList.Group>
          {selected && (
            <>
              <ActionList.Divider />
              <ActionList.Item onSelect={() => onChange('')}>{t('createWorkPackage.clear')}</ActionList.Item>
            </>
          )}
        </ActionList>
      </ActionMenu.Overlay>
    </ActionMenu>
  );
}
