import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertIcon } from '@primer/octicons-react';
import { colorOfType } from '../../services/colors';
import type { FieldValue, FormField, ValueProblem } from './formSchema';
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
  TypeColorDot,
} from './atoms';

interface FormFieldControlProps {
  field:FormField;
  value:FieldValue | undefined;
  valueLabel?:string;
  onChange:(value:FieldValue, label?:string) => void;
  autoFocus?:boolean;
  error?:string;
  problem?:ValueProblem;
}

const PROBLEM_MESSAGES:Record<ValueProblem, string> = {
  missing: 'createWorkPackage.requiredField',
  notANumber: 'createWorkPackage.notANumber',
  notAWholeNumber: 'createWorkPackage.notAWholeNumber',
};

const PLACEHOLDERS:Record<string, string> = {
  subject: 'createWorkPackage.subjectPlaceholder',
  project: 'createWorkPackage.projectPlaceholder',
};

// Presented as a picker; a search for people stays plain.
const PICKER_KEYS = ['project'];

export const FormFieldControl = ({
  field,
  value,
  valueLabel,
  onChange,
  autoFocus,
  error,
  problem,
}:FormFieldControlProps) => {
  const { t } = useTranslation();
  const id = `op-bn-create-wp-${field.key}`;
  // What was just typed speaks before what the API said about an earlier value.
  const message = problem ? t(PROBLEM_MESSAGES[problem]) : error;
  const errorId = message ? `${id}-error` : undefined;
  const invalid = { 'aria-invalid': message ? true : undefined, 'aria-describedby': errorId };
  const textValue = typeof value === 'string' ? value : '';
  const ownPlaceholder = PLACEHOLDERS[field.key];
  const placeholder = field.placeholder ?? (ownPlaceholder ? t(ownPlaceholder) : undefined);
  const colorDot = field.key === 'type' && textValue
    ? <TypeColorDot $color={colorOfType(textValue)} />
    : null;

  const withError = (children:ReactNode) => (
    <FieldRow $invalid={Boolean(message)}>
      {children}
      {message && <FieldError id={errorId}>{message}</FieldError>}
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
        <SelectWrapper $withColorDot={Boolean(colorDot)}>
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
          {colorDot}
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
          valueLabel={valueLabel}
          placeholder={placeholder ?? t('createWorkPackage.searchPlaceholder')}
          withArrows={PICKER_KEYS.includes(field.key)}
          invalid={Boolean(message)}
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
    // Held as text: a number input hands over an empty value for what it cannot
    // read, which would leave the form refusing input it does not point at.
    case 'number':
      control = textInput('text', { inputMode: field.integer ? 'numeric' : 'decimal' });
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
