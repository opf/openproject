import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertIcon } from '@primer/octicons-react';
import type { FieldValue, FormField } from './formSchema';
import { AllowedValuesTypeahead } from './AllowedValuesTypeahead';
import { PickerArrows } from './PickerArrows';
import {
  CheckboxRow,
  FieldLabel,
  FieldRow,
  Notice,
  RequiredMark,
  SelectControl,
  SelectWrapper,
  TextAreaControl,
  TextControl,
} from './atoms';

interface FormFieldControlProps {
  field:FormField;
  value:FieldValue | undefined;
  onChange:(value:FieldValue) => void;
  autoFocus?:boolean;
}

const TEXT_INPUT_TYPES:Record<string, string> = {
  text: 'text',
  number: 'number',
  date: 'date',
};

const PLACEHOLDERS:Record<string, string> = {
  subject: 'createWorkPackage.subjectPlaceholder',
  project: 'createWorkPackage.projectPlaceholder',
};

// Presented as a picker; a search for people stays plain.
const PICKER_KEYS = ['project'];

export const FormFieldControl = ({ field, value, onChange, autoFocus }:FormFieldControlProps) => {
  const { t } = useTranslation();
  const id = `op-bn-create-wp-${field.key}`;
  const textValue = typeof value === 'string' ? value : '';
  const ownPlaceholder = PLACEHOLDERS[field.key];
  const placeholder = field.placeholder ?? (ownPlaceholder ? t(ownPlaceholder) : undefined);

  if (field.kind === 'unsupported') {
    return (
      <FieldRow>
        <Notice>
          <AlertIcon size={14} />
          <span>{t('createWorkPackage.unsupportedField', { field: field.label })}</span>
        </Notice>
      </FieldRow>
    );
  }

  if (field.kind === 'checkbox') {
    return (
      <FieldRow>
        <CheckboxRow>
          <input
            id={id}
            type="checkbox"
            checked={value === true}
            onChange={(event) => onChange(event.target.checked)}
          />
          <span>{field.label}</span>
        </CheckboxRow>
      </FieldRow>
    );
  }

  let control:ReactNode;
  if (field.kind === 'select') {
    control = (
      <SelectWrapper>
        <SelectControl id={id} value={textValue} onChange={(event) => onChange(event.target.value)}>
          <option value="" disabled>
            {placeholder ?? t('createWorkPackage.selectPlaceholder')}
          </option>
          {(field.allowedValues ?? []).map((allowed) => (
            <option key={allowed.href} value={allowed.href}>{allowed.label}</option>
          ))}
        </SelectControl>
        <PickerArrows />
      </SelectWrapper>
    );
  } else if (field.kind === 'typeahead') {
    control = (
      <AllowedValuesTypeahead
        id={id}
        label={field.label}
        href={field.allowedValuesHref ?? ''}
        value={textValue}
        placeholder={placeholder ?? t('createWorkPackage.searchPlaceholder')}
        withArrows={PICKER_KEYS.includes(field.key)}
        onChange={onChange}
      />
    );
  } else if (field.kind === 'textarea') {
    control = (
      <TextAreaControl
        id={id}
        maxLength={field.maxLength}
        value={textValue}
        onChange={(event) => onChange(event.target.value)}
      />
    );
  } else {
    control = (
      <TextControl
        id={id}
        autoFocus={autoFocus}
        type={TEXT_INPUT_TYPES[field.kind] ?? 'text'}
        maxLength={field.kind === 'text' ? field.maxLength : undefined}
        placeholder={placeholder}
        value={textValue}
        onChange={(event) => onChange(event.target.value)}
      />
    );
  }

  return (
    <FieldRow>
      <FieldLabel htmlFor={id}>
        {field.label}
        {field.required && <RequiredMark> *</RequiredMark>}
      </FieldLabel>
      {control}
    </FieldRow>
  );
};
