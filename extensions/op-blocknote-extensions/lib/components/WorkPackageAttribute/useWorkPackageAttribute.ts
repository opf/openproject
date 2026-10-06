import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import { useWorkPackageSchema } from '../../hooks/useWorkPackageSchema';
import type { WorkPackage } from '../../openProjectTypes';
import { findAttribute, formatAttributeValue, type WorkPackageAttribute } from './attributes';

export interface ReadyAttribute {
  state:'ready';
  workPackage:WorkPackage;
  attribute:WorkPackageAttribute;
  value:string;
}

export type ResolvedAttribute = { state:'loading' | 'unauthorized' | 'error' | 'missing' } | ReadyAttribute;

export function useAttributeFormatOptions() {
  const { t, i18n } = useTranslation();
  return useMemo(() => ({
    locale: i18n.language,
    yes: t('workPackageAttribute.yes'),
    no: t('workPackageAttribute.no'),
    days: (count:number) => t('workPackageAttribute.days', { count }),
  }), [t, i18n.language]);
}

export function useWorkPackageAttribute(wpid:string, reference:string):ResolvedAttribute {
  const numericId = /^\d+$/.test(wpid) ? Number(wpid) : undefined;
  const { workPackage, loading, unauthorized, error } = useWorkPackage(numericId);
  const schemaHref = workPackage?._links?.schema?.href;
  const { schema, loading: schemaLoading, error: schemaError } = useWorkPackageSchema(schemaHref);
  const formatOptions = useAttributeFormatOptions();

  return useMemo(() => {
    if (unauthorized) return { state: 'unauthorized' };
    if (error || schemaError || numericId === undefined) return { state: 'error' };
    if (loading || schemaLoading || !workPackage) return { state: 'loading' };
    if (!schema) return { state: 'error' };

    const attribute = findAttribute(schema, reference);
    if (!attribute) return { state: 'missing' };
    return { state: 'ready', workPackage, attribute, value: formatAttributeValue(workPackage, attribute, formatOptions) };
  }, [unauthorized, error, schemaError, numericId, loading, schemaLoading, workPackage, schema, reference, formatOptions]);
}
