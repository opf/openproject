import { Injectable, inject } from '@angular/core';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Injectable({ providedIn: 'root' })
export class JobStatusModalService {
  protected pathHelper = inject(PathHelperService);
  protected turboRequests = inject(TurboRequestsService);


  public show(jobId:string):void {
    void this.turboRequests.requestStream(this.jobModalUrl(jobId));
  }

  private jobModalUrl(jobId:string):string {
    return this.pathHelper.jobStatusModalPath(jobId);
  }
}
