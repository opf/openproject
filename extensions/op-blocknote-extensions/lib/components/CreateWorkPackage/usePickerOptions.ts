import { useEffect, useMemo, useState } from 'react';
import type { KeyboardEvent } from 'react';
import { fetchAllowedValues } from '../../services/openProjectApi';
import type { AllowedValuesQuery } from '../../services/openProjectApi';
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
  values?:AllowedValue[];
  favoredOnly?:boolean;
  nested?:boolean;
  searchedInBrowser?:boolean;
}

export interface PickerOptions {
  options:ListedValue[];
  loading:boolean;
  toggleExpanded:(href:string) => void;
  expand:(hrefs:string[]) => void;
}

function matching(values:AllowedValue[], query:string):AllowedValue[] {
  const term = query.trim().toLowerCase();
  return term ? values.filter((value) => value.label.toLowerCase().includes(term)) : values;
}

function askApi(href:string, query:string, asking:AllowedValuesQuery):Promise<AllowedValue[]> {
  return fetchAllowedValues(href, query, asking).then(({ resources, filtered }) => {
    const term = filtered ? '' : query;

    return matching(toAllowedValues(resources), term)
      .filter((option) => !asking.favoredOnly || option.favored);
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

export function foldsBranch(
  event:KeyboardEvent,
  focused:ListedValue | undefined,
  toggleExpanded:(href:string) => void
):boolean {
  if (!focused) return false;

  const unfolds = event.key === 'ArrowRight' && focused.hasChildren && !focused.expanded;
  const folds = event.key === 'ArrowLeft' && focused.expanded;
  if (!unfolds && !folds) return false;

  event.preventDefault();
  toggleExpanded(focused.href);
  return true;
}

export function usePickerOptions({
  href,
  query,
  isOpen,
  values,
  favoredOnly = false,
  nested = false,
  searchedInBrowser = false,
}:PickerOptionsInput):PickerOptions {
  const [fetched, setFetched] = useState<AllowedValue[]>([]);
  const [loaded, setLoaded] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(new Set());

  const listedBySchema = values !== undefined;
  const searchedHere = listedBySchema || searchedInBrowser;
  const apiTerm = searchedHere ? '' : query;
  const asked = JSON.stringify([href, apiTerm, favoredOnly, nested]);

  const expand = (hrefs:string[]) => {
    if (hrefs.length > 0) setExpanded((current) => new Set([...current, ...hrefs]));
  };

  useEffect(() => {
    if (!isOpen || listedBySchema) return;

    let active = true;

    const read = () => {
      remember(asked, () => askApi(href, apiTerm, { favoredOnly, nested, whole: searchedHere }))
        .then((found) => {
          if (!active) return;
          setFetched(found);
          if (apiTerm.trim()) expand(found.flatMap((option) => option.ancestors ?? []));
        })
        .catch((error:unknown) => {
          if (!active) return;
          console.error('[create work package] Failed to load allowed values:', error);
          setFetched([]);
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
  }, [href, apiTerm, isOpen, favoredOnly, nested, asked, listedBySchema, searchedHere]);

  const options = useMemo(() => {
    const offered = values ?? fetched;
    const term = searchedHere ? query.trim() : '';
    if (!term) return listedValues(offered, expanded);

    // Nothing the term matched hides behind a branch left folded.
    const found = matching(offered, term);
    const branches = new Set([...expanded, ...found.flatMap((option) => option.ancestors ?? [])]);

    return listedValues(found, branches);
  }, [values, fetched, query, expanded, searchedHere]);

  const toggleExpanded = (target:string) => {
    setExpanded((current) => {
      const next = new Set(current);
      if (!next.delete(target)) next.add(target);
      return next;
    });
  };

  return { options, loading: !listedBySchema && loaded !== asked, toggleExpanded, expand };
}
