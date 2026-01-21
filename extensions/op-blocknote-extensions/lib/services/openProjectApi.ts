
import type {OpenProjectResponse, StatusCollection, TypeCollection, WorkPackage} from "../openProjectTypes";

let baseUrl = "https://openproject.local";


export class OpenProjectApiError extends Error {
  responseStatus?: number;

  constructor(message: string, responseStatus?: number) {
    super(message);
    this.responseStatus = responseStatus;
    this.name = "OpenProjectApiError";
  }
}

export function initOpenProjectApi(config: { baseUrl: string }) {
  baseUrl = config.baseUrl;
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.slice(0, -1);
  }
}

async function get<T>(endpoint: string): Promise<T> {
  const response = await fetch(`${baseUrl}${endpoint}`, {
    method: "GET",
    headers: { "Content-Type": "application/json" },
  });
  if (!response.ok) {
    throw new OpenProjectApiError(`HTTP error! status: ${response.status} - ${response.statusText}`, response.status);
  }
  return response.json();
}

export function linkToWorkPackage(id: number): string {
  if (isNaN(id) || id <= 0) {
    throw new OpenProjectApiError(`Invalid work package ID: ${id}`);
  }
  return `${baseUrl}/wp/${id}`;
}

export function fetchWorkPackage(id: number): Promise<WorkPackage> {
  if (isNaN(id) || id <= 0) {
    return Promise.reject(new OpenProjectApiError(`Invalid work package ID: ${id}`));
  }
  return get<WorkPackage>(`/api/v3/work_packages/${id}`);
}

export function fetchStatuses(): Promise<StatusCollection> {
  return get<StatusCollection>(`/api/v3/statuses`);
}

export function fetchTypes(): Promise<TypeCollection> {
  return get<TypeCollection>(`/api/v3/types`);
}

export async function searchWorkPackages(query: string): Promise<WorkPackage[]> {
  const filters = encodeURIComponent(`[{"typeahead":{"operator":"**","values":["${query}"]}}]`);
  const sortBy = encodeURIComponent(`[["updatedAt","desc"]]`);

  const endpoint = `/api/v3/work_packages?filters=${filters}&sortBy=${sortBy}`;
  const data = await get<OpenProjectResponse>(endpoint);
  return data?._embedded?.elements as unknown as WorkPackage[] ?? [];
}
