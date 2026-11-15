import type { WorkPackage, WorkPackageForm, WorkPackagePayload } from '../../openProjectTypes';
import { get, post } from './client';
import { OpenProjectApiError } from './errors';

/**
 * Asks the API which attributes a new work package needs: an empty payload yields
 * the bare schema, sending the project back its types, the type its statuses.
 */
export function fetchWorkPackageCreateForm(payload:WorkPackagePayload = {}):Promise<WorkPackageForm> {
  return post<WorkPackageForm>('/api/v3/work_packages/form', payload);
}

export function createWorkPackage(payload:WorkPackagePayload):Promise<WorkPackage> {
  return post<WorkPackage>('/api/v3/work_packages', payload);
}

/*  The project picker's endpoint is guarded by the very `add_work_packages` permission
 *  the create form needs, so its refusal is the permission answer.  */
const CREATE_PERMISSION_PROBE = '/api/v3/work_packages/available_projects?pageSize=1';

let createPermission = false;
let createPermissionProbe:Promise<boolean> = Promise.resolve(createPermission);

/** Sent by initialization, before any entry point to the create form is drawn. */
export function probeCreateWorkPackagePermission():Promise<boolean> {
  createPermissionProbe = get(CREATE_PERMISSION_PROBE)
    .then(() => true)
    // Only a refusal speaks for the permission: anything else is an instance in trouble,
    // which the create form goes on reporting as it did before.
    .catch((error:unknown) => !(error instanceof OpenProjectApiError && error.responseStatus === 403))
    .then((allowed) => {
      createPermission = allowed;
      return allowed;
    });

  return createPermissionProbe;
}

/** Denied until the probe answers, so no entry point is drawn on an unknown permission. */
export function canCreateWorkPackages():boolean {
  return createPermission;
}

/** Resolves with that probe's answer, for entry points drawn while it is still in flight. */
export function whenCreateWorkPackagePermissionKnown():Promise<boolean> {
  return createPermissionProbe;
}
