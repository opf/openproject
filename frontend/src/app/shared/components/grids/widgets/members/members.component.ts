import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { MembershipResource } from 'core-app/features/hal/resources/membership-resource';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';

const DISPLAYED_MEMBERS_LIMIT = 100;

@Component({
  templateUrl: './members.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./members.component.sass'],
})
export class WidgetMembersComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    add: this.i18n.t('js.grid.widgets.members.add'),
    noResults: this.i18n.t('js.grid.widgets.members.no_results'),
    viewAll: this.i18n.t('js.grid.widgets.members.view_all_members'),
  };

  public totalMembers:number;

  public entriesByRoles:{ [roleId:string]:{ role:RoleResource, users:HalResource[] } } = {};

  private entriesLoaded = false;

  public membersAddable$:Observable<boolean>;

  constructor(
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly i18n:I18nService,
    protected readonly injector:Injector,
    readonly currentProject:CurrentProjectService,
    readonly cdr:ChangeDetectorRef,
  ) {
    super(i18n, injector);
  }

  ngOnInit() {
    this
      .apiV3Service
      .memberships
      .list(this.listMembersParams)
      .subscribe((collection) => {
        this.partitionEntriesByRole(collection.elements);
        this.sortUsersByName();
        this.totalMembers = collection.total;

        this.entriesLoaded = true;
        this.cdr.detectChanges();
      });

    this.membersAddable$ = this
      .apiV3Service
      .memberships
      .available_projects
      .list(this.listAvailableProjectsParams)
      .pipe(
        map((collection) => collection.total > 0),
      );
  }

  public get isEditable() {
    return false;
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
      { count: DISPLAYED_MEMBERS_LIMIT, total: this.totalMembers },
    );
  }

  public get projectMembershipsPath() {
    return this.pathHelper.projectMembershipsPath(this.currentProject.identifier!);
  }

  public get usersByRole() {
    return Object.values(this.entriesByRoles);
  }

  private partitionEntriesByRole(memberships:MembershipResource[]) {
    memberships.forEach((membership) => {
      membership.roles.forEach((role) => {
        if (!this.entriesByRoles[role.id!]) {
          this.entriesByRoles[role.id!] = { role, users: [] };
        }

        this.entriesByRoles[role.id!].users.push(membership.principal);
      });
    });
  }

  private sortUsersByName() {
    Object.values(this.entriesByRoles).forEach((entry) => {
      entry.users.sort((a, b) => a.name.localeCompare(b.name));
    });
  }

  private get listMembersParams() {
    const params:ApiV3ListParameters = { sortBy: [['created_at', 'desc']], pageSize: DISPLAYED_MEMBERS_LIMIT };

    if (this.currentProject.id) {
      params.filters = [['project_id', '=', [this.currentProject.id]]];
    }

    return params;
  }

  private get listAvailableProjectsParams() {
    // It would make sense to set the pageSize but the backend for projects
    // returns an upaginated list which does not support that.
    const params:ApiV3ListParameters = {};

    if (this.currentProject.id) {
      params.filters = [['id', '=', [this.currentProject.id]]];
    }

    return params;
  }
}
