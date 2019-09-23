import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {Component, OnInit, ChangeDetectorRef, Injector, ChangeDetectionStrategy} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {DmListParameter} from "core-app/modules/hal/dm-services/dm.service.interface";
import {MembershipResource} from "core-app/modules/hal/resources/membership-resource";
import {MembershipDmService} from "core-app/modules/hal/dm-services/membership-dm.service";
import {RoleResource} from "core-app/modules/hal/resources/role-resource";

const DISPLAYED_MEMBERS_LIMIT = 100;

@Component({
  templateUrl: './members.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./members.component.sass']
})
export class WidgetMembersComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    add: this.i18n.t('js.grid.widgets.members.add'),
    noResults: this.i18n.t('js.grid.widgets.members.no_results'),
    viewAll: this.i18n.t('js.grid.widgets.members.view_all_members'),
  };

  public totalMembers:number;
  public entriesByRoles:{[roleId:string]:{role:RoleResource, users:UserResource[]}} = {};
  private entriesLoaded = false;
  public membersAddable:boolean = false;

  constructor(readonly pathHelper:PathHelperService,
              readonly i18n:I18nService,
              protected readonly injector:Injector,
              readonly membershipDm:MembershipDmService,
              readonly currentProject:CurrentProjectService,
              readonly cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.membershipDm
      .list(this.listMembersParams)
      .then(collection => {
        this.partitionEntriesByRole(collection.elements);
        this.sortUsersByName();
        this.totalMembers = collection.total;

        this.entriesLoaded = true;
        this.cdr.detectChanges();
      });

    this.membershipDm
      .listAvailableProjects(this.listAvailableProjectsParams)
      .then(collection => {
        this.membersAddable = collection.total > 0;
      })
      .catch(() => {
        // nothing bad, the user is just not allowed to add members to the project

      });
  }

  public get isEditable() {
    return false;
  }

  public userPath(user:UserResource) {
    return this.pathHelper.userPath(user.id!);
  }

  public userName(user:UserResource) {
    return user.name;
  }

  public get noMembers() {
    return this.entriesLoaded && !Object.keys(this.entriesByRoles).length;
  }

  public get moreMembers() {
    return this.entriesLoaded && this.totalMembers > DISPLAYED_MEMBERS_LIMIT;
  }

  public get moreMembersText() {
    return I18n.t(
        'js.grid.widgets.members.too_many',
        { count: DISPLAYED_MEMBERS_LIMIT, total: this.totalMembers }
      );
  }

  public get projectMembershipsPath() {
    return this.pathHelper.projectMembershipsPath(this.currentProject.identifier!);
  }

  public get usersByRole() {
    return Object.values(this.entriesByRoles);
  }

  public isGroup(principal:UserResource) {
    return this.pathHelper.api.v3.groups.id(principal.id!).toString() === principal.href;
  }

  private partitionEntriesByRole(memberships:MembershipResource[]) {
    memberships.forEach(membership => {
      membership.roles.forEach((role) => {
        if (!this.entriesByRoles[role.id!]) {
          this.entriesByRoles[role.id!] = { role: role, users: [] };
        }

        this.entriesByRoles[role.id!].users.push(membership.principal);
      });
    });
  }

  private sortUsersByName() {
    Object.values(this.entriesByRoles).forEach(entry => {
      entry.users.sort((a, b) => {
        return this.userName(a).localeCompare(this.userName(b));
      });
    });
  }

  private get listMembersParams() {
    let params:DmListParameter = { sortBy: [['created_on', 'desc']], pageSize: DISPLAYED_MEMBERS_LIMIT };

    if (this.currentProject.id) {
      params['filters'] = [['project_id', '=', [this.currentProject.id]]];
    }

    return params;
  }

  private get listAvailableProjectsParams() {
    // It would make sense to set the pageSize but the backend for projects
    // returns an upaginated list which does not support that.
    let params:DmListParameter = {};

    if (this.currentProject.id) {
      params['filters'] = [['id', '=', [this.currentProject.id]]];
    }

    return params;
  }
}
