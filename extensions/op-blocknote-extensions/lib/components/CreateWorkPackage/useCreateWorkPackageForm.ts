import { useEffect, useRef, useState } from 'react';
import type { WorkPackage, WorkPackageForm, WorkPackagePayload } from '../../openProjectTypes';
import { createWorkPackage, fetchWorkPackageCreateForm, OpenProjectApiError } from '../../services/openProjectApi';
import {
  allowedValueOf,
  applyLabel,
  applyValue,
  buildCreatePayload,
  clearsOtherValues,
  extraRequiredFields,
  fixedFields,
  isValueFilled,
  missingProblems,
  splitAttributeErrors,
  unsupportedRequiredFields,
  valueProblems,
} from './formSchema';
import type { FieldErrors, FieldLabels, FieldValue, FieldValues, FormField, ValueProblems } from './formSchema';
import { rememberSelection } from './lastSelection';
import { prefillFor, projectPrefill, selectionToRemember } from './prefill';
import type { Prefill } from './prefill';

export interface CreateWorkPackageFormState {
  primaryFields:FormField[];
  extraFields:FormField[];
  values:FieldValues;
  valueLabels:FieldLabels;
  setValue:(key:string, value:FieldValue, label?:string) => void;
  projectHref?:string;
  typeHref?:string;
  isDirty:boolean;
  selectedTypeLabel?:string;
  loading:boolean;
  initialising:boolean;
  loadError:string | null;
  notAllowed:boolean;
  submitting:boolean;
  submitError:string | null;
  fieldErrors:FieldErrors;
  valueProblems:ValueProblems;
  unsupportedFields:FormField[];
  submitEnabled:boolean;
  attemptSubmit:() => string | undefined;
}

function messageOf(error:unknown):string {
  return error instanceof Error ? error.message : String(error);
}

function defaultValuesOf(fields:FormField[]):FieldValues {
  const defaults:FieldValues = {};
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
  const [valueLabels, setValueLabels] = useState<FieldLabels>({});
  const [loaded, setLoaded] = useState<{ project?:string; type?:string } | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [notAllowed, setNotAllowed] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
  const [submitAttempted, setSubmitAttempted] = useState(false);
  const [touched, setTouched] = useState(false);
  const projectPrefilled = useRef(false);

  const projectHref = typeof values.project === 'string' && values.project ? values.project : undefined;
  const typeHref = typeof values.type === 'string' && values.type ? values.type : undefined;

  const loading = loaded === null || loaded.project !== projectHref || loaded.type !== typeHref;

  const initialising = loading && !touched;

  useEffect(() => {
    let active = true;
    const links:WorkPackagePayload['_links'] = {};
    if (projectHref) links.project = { href: projectHref };
    if (typeHref) links.type = { href: typeHref };

    // Only the first bare load prefills, so a cleared project stays cleared.
    const prefillOn = (loaded:WorkPackageForm):Promise<Prefill | undefined> => {
      const loadedSchema = loaded._embedded?.schema;
      const offered = fixedFields(loadedSchema, { project: !!projectHref, type: false });

      if (!projectHref) {
        if (projectPrefilled.current) return Promise.resolve(undefined);
        return projectPrefill(offered.find((field) => field.key === 'project'));
      }
      if (typeHref) return Promise.resolve(undefined);

      return prefillFor(offered, loaded._embedded?.payload ?? {});
    };

    fetchWorkPackageCreateForm(projectHref ? { _links: links } : {})
      .then(async (loaded) => {
        const loadedSchema = loaded._embedded?.schema;
        const prefill = await prefillOn(loaded);
        if (!active) return;

        if (!projectHref) projectPrefilled.current = true;

        setForm(loaded);
        setLoadError(null);
        setNotAllowed(false);
        const defaults = defaultValuesOf(extraRequiredFields(loadedSchema));
        // What is already in the form outranks both: the user has answered it.
        setValues((previous) => ({ ...defaults, ...prefill?.values, ...previous }));
        setValueLabels((previous) => ({ ...prefill?.labels, ...previous }));
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

  const selectedTypeLabel = allowedValueOf(primaryFields.find((field) => field.key === 'type'), typeHref)?.label;

  const setValue = (key:string, value:FieldValue, label?:string) => {
    setTouched(true);
    setSubmitError(null);
    if (clearsOtherValues(key)) setSubmitAttempted(false);
    // Only the corrected field loses its complaint, unless the whole form is reloaded.
    setFieldErrors((previous) => {
      if (clearsOtherValues(key)) return {};
      if (!(key in previous)) return previous;

      const next = { ...previous };
      delete next[key];
      return next;
    });
    setValues((previous) => applyValue(previous, key, value));
    setValueLabels((previous) => applyLabel(previous, key, label));
  };

  const unsupportedFields = unsupportedRequiredFields(allFields);
  const badValues = valueProblems(allFields, values);
  const blocking = { ...missingProblems(allFields, values), ...badValues };
  const blockingKeys = allFields.map((field) => field.key).filter((key) => key in blocking);

  const problems = submitAttempted ? blocking : badValues;

  const submitEnabled =
    !loading &&
    !submitting &&
    loadError === null &&
    !notAllowed &&
    unsupportedFields.length === 0;

  // What was prefilled is nothing the user would miss.
  const isDirty = touched && allFields.some((field) => (field.kind === 'checkbox'
    ? values[field.key] === true
    : isValueFilled(field, values[field.key])));

  const submit = () => {
    if (!form || submitting) return;

    setSubmitting(true);
    setSubmitError(null);
    setFieldErrors({});

    createWorkPackage(buildCreatePayload(form._embedded?.payload ?? {}, allFields, values))
      .then(
        (workPackage) => {
          rememberSelection(selectionToRemember(allFields, values, valueLabels));
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

  const attemptSubmit = () => {
    if (blockingKeys.length === 0) {
      submit();
      return undefined;
    }

    setSubmitAttempted(true);
    return blockingKeys[0];
  };

  return {
    primaryFields,
    extraFields,
    values,
    valueLabels,
    setValue,
    projectHref,
    typeHref,
    isDirty,
    selectedTypeLabel,
    loading,
    initialising,
    loadError: loading ? null : loadError,
    notAllowed: loading ? false : notAllowed,
    submitting,
    submitError,
    fieldErrors,
    valueProblems: problems,
    unsupportedFields,
    submitEnabled,
    attemptSubmit,
  };
}
