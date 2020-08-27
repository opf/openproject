import { Injectable } from '@angular/core';
import {QuerySpaceService} from "core-app/modules/query-space/services/query-space/query-space.service";

@Injectable({
  providedIn: 'root'
})
export class QuerySpaceInstancesTrackerService {
  private _instanceListeningToRouteParams?:QuerySpaceService;
  private _instancesMap:Map<QuerySpaceService, string> = new Map();

  register(instance:QuerySpaceService, queryId?:string) {
    if (queryId) {
      this._instancesMap.set(instance, queryId);
    } else {
      if (this._instanceListeningToRouteParams) {
        throw new Error (`Only one QuerySpaceService is allowed to be loaded from the route params. Please provide a queryId @Input value for the rest of the instances.`);
      } else {
        this._instanceListeningToRouteParams = instance;
        this._instancesMap.set(instance, 'default');
      }
    }
  }

  unregister(instance:QuerySpaceService) {
    if (instance === this._instanceListeningToRouteParams) {
      this._instanceListeningToRouteParams = undefined;
    }

    this._instancesMap.delete(instance);
  }
}
