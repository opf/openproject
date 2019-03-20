import {InputState} from 'reactivestates';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';

export interface WorkPackageTableRefreshRequest {
  /** Whether the refresh should happen visibly */
  visible:boolean;
  /** Whether the first page should be requested */
  firstPage:boolean;
}

@Injectable()
export class WorkPackageTableRefreshService {

  constructor(public querySpace:IsolatedQuerySpace) {
  }

  /**
   * Request a refresh to the work package table.
   * @param reason a reason for logging purposes.
   * @param request WorkPackageTableRefreshRequest
   */
  public request(reason:string, request:Partial<WorkPackageTableRefreshRequest> = {}) {
    let req = { visible: false, firstPage: false, ...request };
    this.state.putValue(req, reason);
  }

  /**
   * Undo any potential pending refresh request
   */
  public clear(reason:string) {
    this.state.clear(reason);
  }

  public get state():InputState<WorkPackageTableRefreshRequest> {
    return this.querySpace.refreshRequired;
  }
}

