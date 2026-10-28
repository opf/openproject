import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import type { WorkPackage } from '../../openProjectTypes';
import { cachedWorkPackageSchema } from '../../services/workPackageLoader';
import { findAttribute, formatAttributeValue, type WorkPackageAttribute } from './attributes';

export type ResolvedAttribute =
  | { state:'loading' | 'unauthorized' | 'error' | 'missing' }
  | { state:'ready', workPackage:WorkPackage, attribute:WorkPackageAttribute, value:string };

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
  const formatOptions = useAttributeFormatOptions();

  return useMemo(() => {
    if (unauthorized) return { state: 'unauthorized' };

    if (error || numericId === undefined) return { state: 'error' };

    if (loading || !workPackage) return { state: 'loading' };

    const schema = cachedWorkPackageSchema(workPackage);
    if (!schema) return { state: 'error' };

    const attribute = findAttribute(schema, reference);
    if (!attribute) return { state: 'missing' };

    return { state: 'ready', workPackage, attribute, value: formatAttributeValue(workPackage, attribute, formatOptions) };
  }, [unauthorized, error, numericId, loading, workPackage, reference, formatOptions]);
}
