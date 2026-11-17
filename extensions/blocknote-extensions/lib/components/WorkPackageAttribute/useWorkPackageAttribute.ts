import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import type { WorkPackage } from '../../openProjectTypes';
import { useDateTimeSettings } from '../../services/dateTimeSettings';
import { cachedWorkPackageSchema } from '../../services/workPackageLoader';
import { findAttribute, formatAttributeValue, type FormatOptions, type WorkPackageAttribute } from './attributes';

export interface ReadyAttribute {
  state:'ready';
  workPackage:WorkPackage;
  attribute:WorkPackageAttribute;
  value:string;
}

export type ResolvedAttribute = { state:'loading' | 'unauthorized' | 'error' | 'missing' } | ReadyAttribute;

export function useAttributeFormatOptions():FormatOptions | null {
  const { t } = useTranslation();
  const dateTimeSettings = useDateTimeSettings();
  return useMemo(() => dateTimeSettings && {
    ...dateTimeSettings,
    yes: t('workPackageAttribute.yes'),
    no: t('workPackageAttribute.no'),
    days: (count:number) => t('workPackageAttribute.days', { count }),
  }, [t, dateTimeSettings]);
}

export function useWorkPackageAttribute(wpid:string, reference:string):ResolvedAttribute {
  const numericId = /^\d+$/.test(wpid) ? Number(wpid) : undefined;
  const { workPackage, loading, unauthorized, error } = useWorkPackage(numericId);
  const formatOptions = useAttributeFormatOptions();

  return useMemo(() => {
    if (unauthorized) return { state: 'unauthorized' };

    if (error || numericId === undefined) return { state: 'error' };

    if (loading || !workPackage || !formatOptions) return { state: 'loading' };

    const schema = cachedWorkPackageSchema(workPackage);
    if (!schema) return { state: 'error' };

    const attribute = findAttribute(schema, reference);
    if (!attribute) return { state: 'missing' };

    return { state: 'ready', workPackage, attribute, value: formatAttributeValue(workPackage, attribute, formatOptions) };
  }, [unauthorized, error, numericId, loading, workPackage, reference, formatOptions]);
}
