import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useWorkPackage } from '../../hooks/useWorkPackage';
import type { WorkPackage } from '../../openProjectTypes';
import { languageDateTimeSettings, useDateTimeSettings } from '../../services/dateTimeSettings';
import { cachedWorkPackageSchema } from '../../services/workPackageLoader';
import {
  findAttribute,
  formatAttributeValue,
  usesDateTimeSettings,
  type FormatOptions,
  type WorkPackageAttribute,
} from './attributes';

export interface ReadyAttribute {
  state:'ready';
  workPackage:WorkPackage;
  attribute:WorkPackageAttribute;
  value:string;
}

export interface UnresolvedAttribute {
  state:'loading' | 'unauthorized' | 'error' | 'missing';
}

export type ResolvedAttribute = UnresolvedAttribute | ReadyAttribute;

export function useAttributeFormatOptions(attribute:WorkPackageAttribute | undefined):FormatOptions | null {
  const { t, i18n } = useTranslation();
  const needsUserSettings = !!attribute && usesDateTimeSettings(attribute);
  const userSettings = useDateTimeSettings(needsUserSettings);

  return useMemo(() => {
    const dateTimeSettings = needsUserSettings ? userSettings : languageDateTimeSettings(i18n.language);
    return dateTimeSettings && {
      ...dateTimeSettings,
      yes: t('workPackageAttribute.yes'),
      no: t('workPackageAttribute.no'),
      days: (count:number) => t('workPackageAttribute.days', { count }),
    };
  }, [t, i18n.language, needsUserSettings, userSettings]);
}

export function useWorkPackageAttribute(wpid:string, reference:string):ResolvedAttribute {
  const numericId = /^\d+$/.test(wpid) ? Number(wpid) : undefined;
  const { workPackage, loading, unauthorized, error } = useWorkPackage(numericId);
  const schema = workPackage ? cachedWorkPackageSchema(workPackage) : undefined;
  const attribute = useMemo(() => (schema ? findAttribute(schema, reference) : undefined), [schema, reference]);
  const formatOptions = useAttributeFormatOptions(attribute);

  return useMemo(() => {
    if (unauthorized) return { state: 'unauthorized' };

    if (error || numericId === undefined) return { state: 'error' };

    if (loading || !workPackage) return { state: 'loading' };

    if (!schema) return { state: 'error' };

    if (!attribute) return { state: 'missing' };

    if (!formatOptions) return { state: 'loading' };

    return { state: 'ready', workPackage, attribute, value: formatAttributeValue(workPackage, attribute, formatOptions) };
  }, [unauthorized, error, numericId, loading, workPackage, schema, attribute, formatOptions]);
}
