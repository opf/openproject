import type { StatusCollection, TypeCollection } from '../../openProjectTypes';
import { get } from './client';

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
