import { useEffect, useMemo, useState } from 'react';
import { fetchAllowedValues } from '../../services/openProjectApi';
import { listedValues, toAllowedValues } from './formSchema';
import type { AllowedValue, ListedValue } from './formSchema';

const SEARCH_DEBOUNCE = 300;

const rememberedValues = new Map<string, Promise<AllowedValue[]>>();

export function clearPickerCache():void {
  rememberedValues.clear();
}

export interface PickerOptionsInput {
  href:string;
  query:string;
  isOpen:boolean;
  favoredOnly?:boolean;
  nested?:boolean;
}

export interface PickerOptions {
  options:ListedValue[];
  loading:boolean;
  toggleExpanded:(href:string) => void;
  expand:(hrefs:string[]) => void;
}

function askApi(href:string, query:string, favoredOnly:boolean, nested:boolean):Promise<AllowedValue[]> {
  return fetchAllowedValues(href, query, { favoredOnly, nested }).then(({ resources, filtered }) => {
    const term = filtered ? '' : query.trim().toLowerCase();

    return toAllowedValues(resources)
      .filter((option) => !term || option.label.toLowerCase().includes(term))
      .filter((option) => !favoredOnly || option.favored);
  });
}

function remember(key:string, ask:() => Promise<AllowedValue[]>):Promise<AllowedValue[]> {
  const known = rememberedValues.get(key);
  if (known) return known;

  const answer = ask();
  rememberedValues.set(key, answer);

  return answer.catch((error:unknown) => {
    rememberedValues.delete(key);
    throw error;
  });
}

export function usePickerOptions({
  href,
  query,
  isOpen,
  favoredOnly = false,
  nested = false,
}:PickerOptionsInput):PickerOptions {
  const [values, setValues] = useState<AllowedValue[]>([]);
  const [loaded, setLoaded] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(new Set());

  const asked = JSON.stringify([href, query, favoredOnly, nested]);

  const expand = (hrefs:string[]) => {
    if (hrefs.length > 0) setExpanded((current) => new Set([...current, ...hrefs]));
  };

  useEffect(() => {
    if (!isOpen) return;

    let active = true;

    const read = () => {
      remember(asked, () => askApi(href, query, favoredOnly, nested))
        .then((found) => {
          if (!active) return;
          setValues(found);
          if (query.trim()) expand(found.flatMap((option) => option.ancestors ?? []));
        })
        .catch((error:unknown) => {
          if (!active) return;
          console.error('[create work package] Failed to load allowed values:', error);
          setValues([]);
        })
        .finally(() => {
          if (active) setLoaded(asked);
        });
    };

    if (rememberedValues.has(asked)) {
      read();
      return () => { active = false; };
    }

    const timer = setTimeout(read, SEARCH_DEBOUNCE);

    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [href, query, isOpen, favoredOnly, nested, asked]);

  const options = useMemo(() => listedValues(values, expanded), [values, expanded]);

  const toggleExpanded = (target:string) => {
    setExpanded((current) => {
      const next = new Set(current);
      if (!next.delete(target)) next.add(target);
      return next;
    });
  };

  return { options, loading: loaded !== asked, toggleExpanded, expand };
}
