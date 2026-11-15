import type {
  HalCollection,
  NonWorkingDay,
  OpenProjectConfiguration,
  PriorityCollection,
  StatusCollection,
  TypeCollection,
  Weekday,
} from '../../openProjectTypes';
import { get, proxiedUrl } from './client';

async function getWithErrorLog<T>(endpoint:string, caller:string):Promise<T> {
  try {
    return await get<T>(endpoint);
  } catch (error) {
    console.error(`[OpenProjectApi] ${caller} failed:`, error);
    throw error;
  }
}

export function fetchStatuses():Promise<StatusCollection> {
  return getWithErrorLog<StatusCollection>('/api/v3/statuses', 'fetchStatuses');
}

export function fetchTypes():Promise<TypeCollection> {
  return getWithErrorLog<TypeCollection>('/api/v3/types', 'fetchTypes');
}

export function fetchConfiguration():Promise<OpenProjectConfiguration> {
  return get<OpenProjectConfiguration>('/api/v3/configuration');
}

export async function fetchWeekdays():Promise<Weekday[]> {
  const data = await get<HalCollection<Weekday>>('/api/v3/days/week');
  return data._embedded?.elements ?? [];
}

export async function fetchNonWorkingDays(year:number):Promise<string[]> {
  const filters = [{ date: { operator: '<>d', values: [`${year}-01-01`, `${year}-12-31`] } }];
  const params = new URLSearchParams({ filters: JSON.stringify(filters) });

  const data = await get<HalCollection<NonWorkingDay>>(`/api/v3/days/non_working?${params.toString()}`);
  return (data._embedded?.elements ?? []).map((day) => day.date);
}

export function fetchPriorities():Promise<PriorityCollection> {
  return getWithErrorLog<PriorityCollection>('/api/v3/priorities', 'fetchPriorities');
}

const USER_HREF = /^\/api\/v3\/users\/\d+$/;

/** Only users have a picture; groups and placeholder users stay with their initials. */
export function avatarUrlOf(principalHref:string | null | undefined):string | undefined {
  return principalHref && USER_HREF.test(principalHref) ? proxiedUrl(`${principalHref}/avatar`) : undefined;
}
