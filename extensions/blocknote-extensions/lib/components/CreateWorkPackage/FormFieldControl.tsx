import type { ReactNode } from 'react';
import { getPrimerDialogs } from '../../services/dialogComponents';
import { useTranslation } from 'react-i18next';
import { AlertIcon } from '@primer/octicons-react';
import { colorOfType } from '../../services/colors';
import { hrefsOf } from './formSchema';
import type { FieldValue, FormField, ValueProblem } from './formSchema';
import { AllowedValuesSelect } from '../Shared/AllowedValuesSelect';
import { AllowedValuesTypeahead } from './AllowedValuesTypeahead';
import { TypeActionMenu } from './TypeActionMenu';
import { DatePicker } from './DatePicker';
import { MultiValueTypeahead } from './MultiValueTypeahead';
import { ProjectPicker } from './ProjectPicker';
import {
  CheckboxRow,
  FieldError,
  GeneratedControl,
  GeneratedField,
  GeneratedText,
  TextAreaControl,
} from './atoms';
import {
  FieldHint,
  FieldLabel,
  FieldRow,
  Notice,
  RequiredMark,
  TextControl,
} from '../Shared/atoms';

interface FormFieldControlProps {
  field:FormField;
  value:FieldValue | undefined;
  valueLabel?:string;
  onChange:(value:FieldValue, label?:string) => void;
  error?:string;
  problem?:ValueProblem;
  hint?:string;
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

export const controlIdOf = (key:string):string => `op-bn-create-wp-${key}`;

const PROJECT_KEY = 'project';
export const SUBJECT_KEY = 'subject';

export const FormFieldControl = ({
  field,
  value,
  valueLabel,
  onChange,
  error,
  problem,
  hint,
}:FormFieldControlProps) => {
  const { t } = useTranslation();
  const id = controlIdOf(field.key);
  // What was just typed speaks before what the API said about an earlier value.
  const message = problem ? t(PROBLEM_MESSAGES[problem]) : error;
  const primer = getPrimerDialogs();
  const errorId = message ? `${id}-${primer ? 'validationMessage' : 'error'}` : undefined;
  const hintId = hint ? `${id}-${primer ? 'caption' : 'hint'}` : undefined;
  const describedBy = [errorId, hintId].filter(Boolean).join(' ') || undefined;
  const invalid = { 'aria-invalid': message ? true : undefined, 'aria-describedby': describedBy };
  const textValue = typeof value === 'string' ? value : '';
  const ownPlaceholder = PLACEHOLDERS[field.key];
  const placeholder = field.placeholder ?? (ownPlaceholder ? t(ownPlaceholder) : undefined);
  const withMessages = (children:ReactNode) => (
    <FieldRow $invalid={Boolean(message)}>
      {children}
      {message && <FieldError id={errorId}>{message}</FieldError>}
      {hint && (
        <FieldHint id={hintId} data-testid={hintId}>
          <AlertIcon size={14} />
          <span>{hint}</span>
        </FieldHint>
      )}
    </FieldRow>
  );

  const CheckboxControl = primer?.Checkbox ?? 'input';
  const Area = primer?.Textarea ?? TextAreaControl;

  if (field.kind === 'checkbox') {
    return withMessages(
      <CheckboxRow>
        <CheckboxControl
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

  const textInput = (type:string, extra?:Pick<React.ComponentProps<'input'>, 'autoComplete' | 'maxLength' | 'inputMode'>) => {
    const props = {
      id, type, placeholder, value: textValue,
      onChange: (event:React.ChangeEvent<HTMLInputElement>) => onChange(event.target.value),
      ...invalid, ...extra,
    };
    return primer ? <primer.TextInput block {...extra} type={type} placeholder={placeholder} value={textValue} onChange={props.onChange} />
      : <TextControl {...props} />;
  };

  let control:ReactNode;
  switch (field.kind) {
    case 'select': {
      const select = {
        id, label: field.label, options: field.allowedValues ?? [], value: textValue,
        placeholder: placeholder ?? t('createWorkPackage.selectPlaceholder'),
        invalid: Boolean(message), describedBy, onChange,
      };
      control = primer && field.key === 'type'
        ? <TypeActionMenu {...select} primer={primer} />
        : <AllowedValuesSelect {...select} colorOf={field.key === 'type' ? colorOfType : undefined} />;
      break;
    }
    case 'typeahead': {
      const picker = {
        id,
        label: field.label,
        href: field.allowedValuesHref ?? '',
        value: textValue,
        valueLabel,
        placeholder: placeholder ?? t('createWorkPackage.searchPlaceholder'),
        invalid: Boolean(message),
        describedBy,
        onChange,
      };

      if (primer?.FormResourcePicker && (field.key === PROJECT_KEY || field.key === 'assignee')) {
        control = <primer.FormResourcePicker key={picker.href} resource={field.key} {...picker} />;
        break;
      }

      control = field.key === PROJECT_KEY
        ? <ProjectPicker {...picker} />
        : <AllowedValuesTypeahead {...picker} searchedInBrowser={field.searchedInBrowser} />;
      break;
    }
    case 'multiSelect':
      control = (
        <MultiValueTypeahead
          id={id}
          label={field.label}
          href={field.allowedValuesHref}
          allowedValues={field.allowedValues}
          value={hrefsOf(value)}
          placeholder={placeholder ?? t('createWorkPackage.searchPlaceholder')}
          invalid={Boolean(message)}
          describedBy={errorId}
          searchedInBrowser={field.searchedInBrowser}
          onChange={onChange}
        />
      );
      break;
    // Nothing to fill in: what the type will generate says itself why.
    case 'generated': {
      const generated = placeholder ?? '';
      control = (
        <GeneratedField>
          <GeneratedControl id={id} rows={1} readOnly value={generated} {...invalid} />
          <GeneratedText>{generated}</GeneratedText>
        </GeneratedField>
      );
      break;
    }
    case 'textarea':
      control = (
        <Area
          {...(primer && { block: true })}
          id={id}
          maxLength={field.maxLength}
          autoComplete="off"
          value={textValue}
          onChange={(event) => onChange(event.target.value)}
          {...invalid}
        />
      );
      break;
    case 'text':
      control = textInput('text', {
        maxLength: field.maxLength,
        autoComplete: field.key === SUBJECT_KEY ? 'off' : undefined,
      });
      break;
    case 'date':
    case 'datetime':
      control = (
        <DatePicker
          id={id}
          withTime={field.kind === 'datetime'}
          value={textValue}
          placeholder={placeholder}
          invalid={Boolean(message)}
          describedBy={describedBy}
          onChange={onChange}
        />
      );
      break;
    // Held as text: a number input hands over an empty value for what it cannot
    // read, which would leave the form refusing input it does not point at.
    case 'number':
      control = textInput('text', {
        inputMode: field.integer ? 'numeric' : 'decimal',
        autoComplete: 'off',
      });
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

  if (primer) {
    return (
      <primer.FormControl id={id} required={field.required} className="op-bn-dialog-field">
        <primer.FormControl.Label htmlFor={id}>{field.label}</primer.FormControl.Label>
        {control}
        {message && <primer.FormControl.Validation variant="error">{message}</primer.FormControl.Validation>}
        {hint && <primer.FormControl.Caption>{hint}</primer.FormControl.Caption>}
      </primer.FormControl>
    );
  }

  return withMessages(
    <>
      <FieldLabel htmlFor={id}>
        {field.label}
        {field.required && <RequiredMark> *</RequiredMark>}
      </FieldLabel>
      {control}
    </>
  );
};
