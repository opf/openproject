import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { CurrentUserService } from 'core-app/components/user/current-user.service';
import { OpModalLocalsMap } from 'core-app/modules/modal/modal.types';
import { OpModalComponent } from 'core-app/modules/modal/modal.component';
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { RoleResource } from "core-app/modules/hal/resources/role-resource";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";

enum Steps {
  ProjectSelection,
  Principal,
  Role,
  Message,
  Summary,
  Success,
}

export enum PrincipalType {
  User = 'User',
  Placeholder = 'PlaceholderUser',
  Group = 'Group',
}

@Component({
  templateUrl: './invite-user.component.html',
  styleUrls: ['./invite-user.component.sass'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InviteUserModalComponent extends OpModalComponent implements OnInit {
  public Steps = Steps;
  public step = Steps.ProjectSelection;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  /* Data that is retured from the modal on close */
  public data:any = null;

  public type:PrincipalType|null = null;
  public project:ProjectResource|null = null;
  public principal:HalResource|null = null;
  public role:RoleResource|null = null;
  public message = '';
  public createdNewPrincipal = false;

  public get loading() {
    return this.locals.projectId && !this.project;
  }

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly apiV3Service:APIV3Service,
    readonly currentUserService:CurrentUserService,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    if (this.locals.projectId) {
      this.apiV3Service.projects.id(this.locals.projectId).get().subscribe(
        data => {
          this.project = data;
          this.cdRef.markForCheck();

          const filters = new ApiV3FilterBuilder();
          filters.add('action', '=', ['users/create', 'memberships/create']);
          filters.add('principal', '=', [this.currentUserService.userId]);
          filters.add('context', '=', [`p${this.project.id}`]);
          this.apiV3Service.capabilities.filtered(filters).get().subscribe((...data) => {
            console.log(data);
          });
        },
        () => {
          this.locals.projectId = null;
          this.cdRef.markForCheck();
        },
      );
    } 
  }

  onProjectSelectionSave({ type, project }:{ type:PrincipalType, project:any }) {
    this.type = type;
    this.project = project;
    this.goTo(Steps.Principal);
  }

  onPrincipalSave({ principal, isAlreadyMember }:{ principal:any, isAlreadyMember:boolean }) {
    this.principal = principal;
    if (isAlreadyMember) {
      return this.closeWithPrincipal();
    }

    this.goTo(Steps.Role);
  }

  onRoleSave(role:RoleResource) {
    this.role = role;

    if (this.type === PrincipalType.Placeholder) {
      this.goTo(Steps.Summary);
    } else {
      this.goTo(Steps.Message);
    }
  }

  onMessageSave({ message }:{ message:string }) {
    this.message = message;
    this.goTo(Steps.Summary);
  }

  onSuccessfulSubmission($event:{ principal:HalResource }) {
    if (this.principal !== $event.principal && this.type === PrincipalType.User) {
      this.createdNewPrincipal = true;
    }
    this.principal = $event.principal;
    this.goTo(Steps.Success);
  }

  goTo(step:Steps) {
    this.step = step;
  }

  closeWithPrincipal() {
    this.data = this.principal;
    this.closeMe();
  }
}
