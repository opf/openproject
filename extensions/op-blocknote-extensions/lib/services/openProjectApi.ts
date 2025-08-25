
import type { OpenProjectResponse, WorkPackage } from "../openProjectTypes";

let baseUrl = "https://openproject.local";

export function initOpenProjectApi(config: { baseUrl: string }) {
  baseUrl = config.baseUrl;
}

async function get<T>(endpoint: string): Promise<T> {
  const response = await fetch(`${baseUrl}${endpoint}`, {
    method: "GET",
    headers: { "Content-Type": "application/json" },
  });
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status} - ${response.statusText}`);
  }
  return response.json();
}

export function linkToWorkPackage(id: string): string {
  return `${baseUrl}/wp/${id}`;
}

export function fetchWorkPackage(id: string): Promise<WorkPackage> {
  return get<WorkPackage>(`/api/v3/work_packages/${id}`);
}

export function fetchStatuses(): Promise<OpenProjectResponse> {
  return get<OpenProjectResponse>(`/api/v3/statuses`);
}

export function fetchProjectTypes(projectId: string): Promise<OpenProjectResponse> {
  return get<OpenProjectResponse>(`/api/v3/projects/${projectId}/types`);
}

export async function searchWorkPackages(query: string): Promise<WorkPackage[]> {
  const endpoint = `/api/v3/work_packages?filters=[{"typeahead":{"operator":"**","values":["${encodeURIComponent(query)}"]}}]`;
  const data = await get<OpenProjectResponse>(endpoint);
  return data?._embedded?.elements as unknown as WorkPackage[] ?? [];
}
