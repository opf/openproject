import { Injectable } from '@angular/core';
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {forkJoin, Observable} from "rxjs";
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
    console.log('usersPath', this.pathHelperService.usersPath(), this.pathHelperService.projectPath('hola'))
  }

  inviteUser(projectId:string, userId:string, roleId:string) {
    /* TODO: waiting for the API to:
    * - handle 'message' property in invitations
    * - handle 'email' invitations
    */
    const requestData = {
      project: {
        href: `/api/v3/projects/${projectId}`
      },
      principal: {
        href: `/api/v3/users/${userId}`,
      },
      roles: [
        {
          href: `/api/v3/roles/${roleId}`,
        }
      ]
    };

    return this.apiV3Service.memberships.post(requestData);
  }

  getRoles(searchTerm:string) {
    return this.apiV3Service
      .roles
      .list({
        filters: [
          ['unit', '=', ['project']],
        ]
      })
      .pipe(
        map((roles:CollectionResource) => roles.elements.filter(role => role.name.includes(searchTerm)))
      );
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
          map(({memberPrincipals, nonMemberPrincipals}) => this.getAllPrincipalsData(memberPrincipals.elements, nonMemberPrincipals.elements)),
          shareReplay(1),
          this.untilDestroyed(),
        );
    }

    return this.principals$
      .pipe(map(allPrincipals => allPrincipals.filter(principal => principal.name?.includes(searchTerm) || principal.email?.includes(searchTerm))));
  }

  getAllPrincipalsData(memberPrincipals:UserResource | GroupResource[], nonMemberPrincipals:UserResource | GroupResource[]):IUserWizardSelectData[] {
    const memberPrincipalsData = memberPrincipals.map(({name, id, email, _type}:IUserWizardSelectData) => ({name, id, email, _type, disabled: true}));
    const nonMemberPrincipalsData = nonMemberPrincipals.map(({name, id, email, _type}:IUserWizardSelectData) => ({name, id, email, _type, disabled: false}));
    const allPrincipals = [...memberPrincipalsData, ...nonMemberPrincipalsData];

    return allPrincipals;
  }

}
