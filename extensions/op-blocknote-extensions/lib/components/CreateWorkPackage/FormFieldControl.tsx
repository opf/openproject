import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertIcon } from '@primer/octicons-react';
import type { FieldValue, FormField } from './formSchema';
import { AllowedValuesTypeahead } from './AllowedValuesTypeahead';
import { PickerArrows } from './PickerArrows';
import {
  CheckboxRow,
  FieldError,
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
  error?:string;
}

const NON_INTEGER = '.,eE';
const NON_INTEGER_PATTERN = new RegExp(`[${NON_INTEGER}]`, 'g');

const PLACEHOLDERS:Record<string, string> = {
  subject: 'createWorkPackage.subjectPlaceholder',
  project: 'createWorkPackage.projectPlaceholder',
};

// Presented as a picker; a search for people stays plain.
const PICKER_KEYS = ['project'];

export const FormFieldControl = ({ field, value, onChange, autoFocus, error }:FormFieldControlProps) => {
  const { t } = useTranslation();
  const id = `op-bn-create-wp-${field.key}`;
  const errorId = error ? `${id}-error` : undefined;
  const invalid = { 'aria-invalid': error ? true : undefined, 'aria-describedby': errorId };
  const textValue = typeof value === 'string' ? value : '';
  const ownPlaceholder = PLACEHOLDERS[field.key];
  const placeholder = field.placeholder ?? (ownPlaceholder ? t(ownPlaceholder) : undefined);

  const withError = (children:ReactNode) => (
    <FieldRow $invalid={Boolean(error)}>
      {children}
      {error && <FieldError id={errorId}>{error}</FieldError>}
    </FieldRow>
  );

  if (field.kind === 'checkbox') {
    return withError(
      <CheckboxRow>
        <input
          id={id}
          type="checkbox"
          checked={value === true}
          onChange={(event) => onChange(event.target.checked)}
          {...invalid}
        />
        <span>{field.label}</span>
      </CheckboxRow>
    );
  }

  const textInput = (type:string, extra?:Partial<React.ComponentProps<typeof TextControl>>) => (
    <TextControl
      id={id}
      autoFocus={autoFocus}
      type={type}
      placeholder={placeholder}
      value={textValue}
      onChange={(event) => onChange(event.target.value)}
      {...invalid}
      {...extra}
    />
  );

  let control:ReactNode;
  switch (field.kind) {
    case 'select':
      control = (
        <SelectWrapper>
          <SelectControl
            id={id}
            value={textValue}
            onChange={(event) => onChange(event.target.value)}
            {...invalid}
          >
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
      break;
    case 'typeahead':
      control = (
        <AllowedValuesTypeahead
          id={id}
          label={field.label}
          href={field.allowedValuesHref ?? ''}
          value={textValue}
          placeholder={placeholder ?? t('createWorkPackage.searchPlaceholder')}
          withArrows={PICKER_KEYS.includes(field.key)}
          invalid={Boolean(error)}
          describedBy={errorId}
          onChange={onChange}
        />
      );
      break;
    case 'textarea':
      control = (
        <TextAreaControl
          id={id}
          maxLength={field.maxLength}
          value={textValue}
          onChange={(event) => onChange(event.target.value)}
          {...invalid}
        />
      );
      break;
    case 'text':
      control = textInput('text', { maxLength: field.maxLength });
      break;
    case 'date':
      control = textInput('date');
      break;
    case 'number':
      control = textInput('number', field.integer
        // The key is refused so no separator appears while typing, the value
        // cleaned so none arrives pasted, rather than the API refusing it later.
        ? {
          step: 1,
          onKeyDown: (event) => { if (NON_INTEGER.includes(event.key)) event.preventDefault(); },
          onChange: (event) => onChange(event.target.value.replace(NON_INTEGER_PATTERN, '')),
        }
        : { step: 'any' });
      break;
    // Also every kind added to the schema reader but not answered here yet.
    default:
      return (
        <FieldRow>
          <Notice>
            <AlertIcon size={14} />
            <span>{t('createWorkPackage.unsupportedField', { field: field.label })}</span>
          </Notice>
        </FieldRow>
      );
  }

  return withError(
    <>
      <FieldLabel htmlFor={id}>
        {field.label}
        {field.required && <RequiredMark> *</RequiredMark>}
      </FieldLabel>
      {control}
    </>
  );
};
