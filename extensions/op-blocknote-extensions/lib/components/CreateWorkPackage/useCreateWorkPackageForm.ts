import { useEffect, useState } from 'react';
import type { WorkPackage, WorkPackageForm, WorkPackagePayload, WorkPackageSchema } from '../../openProjectTypes';
import { createWorkPackage, fetchWorkPackageCreateForm, OpenProjectApiError } from '../../services/openProjectApi';
import {
  applyValue,
  buildCreatePayload,
  clearsOtherValues,
  extraRequiredFields,
  fieldFor,
  fixedFields,
  isValueFilled,
  missingRequiredFields,
  splitAttributeErrors,
  unsupportedRequiredFields,
} from './formSchema';
import type { FieldErrors, FieldValue, FieldValues, FormField } from './formSchema';

export interface CreateWorkPackageFormState {
  primaryFields:FormField[];
  extraFields:FormField[];
  values:FieldValues;
  setValue:(key:string, value:FieldValue) => void;
  projectHref?:string;
  typeHref?:string;
  isDirty:boolean;
  selectedTypeLabel?:string;
  loading:boolean;
  loadError:string | null;
  notAllowed:boolean;
  submitting:boolean;
  submitError:string | null;
  fieldErrors:FieldErrors;
  unsupportedFields:FormField[];
  canSubmit:boolean;
  submit:() => void;
}

function messageOf(error:unknown):string {
  return error instanceof Error ? error.message : String(error);
}

function hrefOf(payload:WorkPackagePayload | undefined, key:string):string | undefined {
  const link = payload?._links?.[key];
  if (!link || Array.isArray(link)) return undefined;
  return link.href ?? undefined;
}

function defaultValuesOf(
  schema:WorkPackageSchema | undefined,
  payload:WorkPackagePayload | undefined,
  fields:FormField[]
):FieldValues {
  const defaults:FieldValues = {};

  const statusHref = hrefOf(payload, 'status');
  if (statusHref && fieldFor(schema, 'status')) defaults.status = statusHref;

  for (const field of fields) {
    if (field.kind === 'checkbox') defaults[field.key] = false;
  }
  return defaults;
}

export function useCreateWorkPackageForm(
  onCreated:(workPackage:WorkPackage) => void
):CreateWorkPackageFormState {
  const [form, setForm] = useState<WorkPackageForm | null>(null);
  const [values, setValues] = useState<FieldValues>({ subject: '' });
  const [loaded, setLoaded] = useState<{ project?:string; type?:string } | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [notAllowed, setNotAllowed] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});

  const projectHref = typeof values.project === 'string' && values.project ? values.project : undefined;
  const typeHref = typeof values.type === 'string' && values.type ? values.type : undefined;

  const loading = loaded === null || loaded.project !== projectHref || loaded.type !== typeHref;

  useEffect(() => {
    let active = true;
    const links:WorkPackagePayload['_links'] = {};
    if (projectHref) links.project = { href: projectHref };
    if (typeHref) links.type = { href: typeHref };

    fetchWorkPackageCreateForm(projectHref ? { _links: links } : {})
      .then((loaded) => {
        if (!active) return;
        setForm(loaded);
        setLoadError(null);
        setNotAllowed(false);
        const schema = loaded._embedded?.schema;
        const defaults = defaultValuesOf(schema, loaded._embedded?.payload, extraRequiredFields(schema));
        setValues((previous) => ({ ...defaults, ...previous }));
      })
      .catch((error:unknown) => {
        if (!active) return;
        console.error('[create work package] Failed to load the work package form:', error);
        // Only the first request speaks for the whole instance.
        const forbidden = !projectHref
          && error instanceof OpenProjectApiError
          && error.responseStatus === 403;
        setNotAllowed(forbidden);
        setLoadError(forbidden ? null : messageOf(error));
      })
      .finally(() => {
        if (active) setLoaded({ project: projectHref, type: typeHref });
      });

    return () => { active = false; };
  }, [projectHref, typeHref]);

  const schema = form?._embedded?.schema;

  const projectLoaded = projectHref !== undefined && loaded?.project === projectHref;
  const selected = {
    project: projectLoaded,
    type: projectLoaded && typeHref !== undefined && loaded?.type === typeHref,
  };

  const primaryFields = fixedFields(schema, selected);
  const extraFields = selected.type ? extraRequiredFields(schema) : [];
  const allFields = [...primaryFields, ...extraFields];

  const selectedTypeLabel = primaryFields
    .find((field) => field.key === 'type')
    ?.allowedValues
    ?.find((allowed) => allowed.href === typeHref)
    ?.label;

  const setValue = (key:string, value:FieldValue) => {
    setSubmitError(null);
    // Only the corrected field loses its complaint, unless the whole form is reloaded.
    setFieldErrors((previous) => {
      if (clearsOtherValues(key)) return {};
      if (!(key in previous)) return previous;

      const next = { ...previous };
      delete next[key];
      return next;
    });
    setValues((previous) => applyValue(previous, key, value));
  };

  const unsupportedFields = unsupportedRequiredFields(allFields);

  const canSubmit =
    !loading &&
    !submitting &&
    loadError === null &&
    !notAllowed &&
    selected.type &&
    unsupportedFields.length === 0 &&
    missingRequiredFields(allFields, values).length === 0;

  const isDirty = allFields.some((field) => field.kind !== 'checkbox' && isValueFilled(field, values[field.key]));

  const submit = () => {
    if (!form || submitting) return;

    setSubmitting(true);
    setSubmitError(null);
    setFieldErrors({});

    createWorkPackage(buildCreatePayload(form._embedded?.payload ?? {}, allFields, values))
      .then(
        (workPackage) => {
          // Not chained behind onCreated: a failed insert must not read as a
          // failed create, which would invite a duplicate.
          setSubmitting(false);
          onCreated(workPackage);
        },
        (error:unknown) => {
          console.error('[create work package] Failed to create the work package:', error);
          const attributed = error instanceof OpenProjectApiError ? error.attributeErrors : {};
          const split = splitAttributeErrors(allFields, attributed);
          const shownAtFields = Object.keys(split.fieldErrors).length > 0;

          setFieldErrors(split.fieldErrors);
          if (shownAtFields) setSubmitError(split.otherMessages.length > 0 ? split.otherMessages.join(' ') : null);
          else setSubmitError(messageOf(error));
          setSubmitting(false);
        }
      );
  };

  return {
    primaryFields,
    extraFields,
    values,
    setValue,
    projectHref,
    typeHref,
    isDirty,
    selectedTypeLabel,
    loading,
    loadError: loading ? null : loadError,
    notAllowed: loading ? false : notAllowed,
    submitting,
    submitError,
    fieldErrors,
    unsupportedFields,
    canSubmit,
    submit,
  };
}
