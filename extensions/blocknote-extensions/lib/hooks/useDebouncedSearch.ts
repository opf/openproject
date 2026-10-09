import { useCallback, useEffect, useRef } from 'react';

interface DebouncedSearchOptions {
  debounce?:number;
  searchBlank?:boolean;
}

/**
 * For BlockNote's `getItems`, which awaits every call: a call superseded by a
 * newer one, or cut off by unmounting, must still settle, so it resolves empty
 * instead of hanging.
 */
export function useDebouncedSearch<T>(
  search:(query:string) => Promise<T[]>,
  { debounce = 300, searchBlank = false }:DebouncedSearchOptions = {},
):(query:string) => Promise<T[]> {
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingResolveRef = useRef<((results:T[]) => void) | null>(null);

  const settlePending = useCallback(() => {
    if (timerRef.current !== null) clearTimeout(timerRef.current);
    timerRef.current = null;
    pendingResolveRef.current?.([]);
    pendingResolveRef.current = null;
  }, []);

  useEffect(() => settlePending, [settlePending]);

  return useCallback((query:string) => {
    settlePending();

    if (!searchBlank && !query.trim()) return Promise.resolve([]);

    return new Promise<T[]>((resolve, reject) => {
      pendingResolveRef.current = resolve;
      timerRef.current = setTimeout(() => {
        timerRef.current = null;
        pendingResolveRef.current = null;
        Promise.resolve().then(() => search(query)).then(resolve, (error:unknown) => {
          reject(error instanceof Error ? error : new Error(String(error)));
        });
      }, debounce);
    });
  }, [search, debounce, searchBlank, settlePending]);
}
