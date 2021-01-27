import { Injectable } from '@angular/core';
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {forkJoin, Observable, of} from "rxjs";
import {map, shareReplay} from "rxjs/operators";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {GroupResource} from "core-app/modules/hal/resources/group-resource";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";

@Injectable({
  providedIn: 'root'
})
export class InviteUserWizardService extends UntilDestroyedMixin {
  principals$:Observable<IUserWizardSelectData[]>;

  constructor(
    private apiV3Service:APIV3Service,
    private pathHelperService:PathHelperService,
  ) {
    super();
  }

  getPrincipals(searchTerm:string, projectId:string, principalType:string):Observable<IUserWizardSelectData[]> {
    if (!this.principals$) {
      const memberPrincipals$ = this.apiV3Service.principals.list({
        filters: [
          ['member', '=', [projectId]],
          ['type', '=', [principalType]],
        ]
      });
      const nonMemberPrincipals$ = this.apiV3Service.principals.list({
        filters: [
          ['status', '!', ['3']], ['member', '!', ['1']],
          ['type', '=', [principalType]],
        ]
      });

      this.principals$ = forkJoin({memberPrincipals: memberPrincipals$, nonMemberPrincipals: nonMemberPrincipals$})
        .pipe(
          map(({memberPrincipals, nonMemberPrincipals}) => this._getAllPrincipalsData(memberPrincipals.elements, nonMemberPrincipals.elements)),
          shareReplay(1),
          this.untilDestroyed(),
        );
    }

    return this.principals$
      .pipe(map(allPrincipals => allPrincipals.filter(principal => principal.name?.toLowerCase().includes(searchTerm?.toLowerCase()) ||
        principal.email?.toLowerCase().includes(searchTerm?.toLowerCase()))));
  }
  // TODO: Type this response
  getRoles(searchTerm:string):Observable<any> {
    return this.apiV3Service
      .roles
      .list({
        filters: [
          ['unit', '=', ['project']],
        ]
      })
      .pipe(
        map((roles:CollectionResource) => roles.elements.filter(role => role.name?.toLowerCase().includes(searchTerm?.toLowerCase())))
      );
  }

  // TODO: Type this response
  finalAction() {
    // TODO:  Implement final action (close dialog and set value to the input?)
    console.log('Final action');
    return of(true);
  }

  // TODO: Type this response
  inviteUser(projectId:string, userId:string, roleId:string, message:string):Observable<any> {
    /* TODO: waiting for the API to:
    * - handle 'message' property in invitations
    * - handle 'email' invitations
    */
    const apiBasePath = this.pathHelperService.api.v3.apiV3Base;
    const projectPath = this.pathHelperService.projectPath(projectId);
    const userPath = this.pathHelperService.userPath(userId);
    const rolePath = this.pathHelperService.rolePath(roleId);
    const requestData = {
      project: {
        href: `${apiBasePath}${projectPath}`
      },
      principal: {
        href: `${apiBasePath}${userPath}`,
      },
      roles: [
        {
          href: `${apiBasePath}${rolePath}`,
        }
      ],
      message
    };

    return this.apiV3Service.memberships.post(requestData);
  }

  private _getAllPrincipalsData(memberPrincipals:UserResource | GroupResource[], nonMemberPrincipals:UserResource | GroupResource[]):IUserWizardSelectData[] {
    const memberPrincipalsData = memberPrincipals.map(({name, id, email, _type}:IUserWizardSelectData) => ({name, id, email, _type, disabled: true}));
    const nonMemberPrincipalsData = nonMemberPrincipals.map(({name, id, email, _type}:IUserWizardSelectData) => ({name, id, email, _type, disabled: false}));
    const allPrincipals = [...memberPrincipalsData, ...nonMemberPrincipalsData];

    return allPrincipals;
  }
}
