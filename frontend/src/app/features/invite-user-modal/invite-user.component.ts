import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PrincipalData } from 'core-app/shared/components/principal/principal-types';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';

enum Steps {
  ProjectSelection,
  Principal,
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

  /* Data that is returned from the modal on close */
  public data:any = null;

  public type:PrincipalType|null = null;

  public project:ProjectResource|null = null;

  public principalData:PrincipalData = {
    principal: null,
    customFields: {},
  };

  public role:RoleResource|null = null;

  public message = '';

  public createdNewPrincipal = false;

  public get loading():boolean {
    return this.locals.projectId && !this.project;
  }

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly apiV3Service:ApiV3Service,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    if (this.locals.projectId) {
      this.apiV3Service.projects.id(this.locals.projectId).get().subscribe(
        (data) => {
          this.project = data;
          this.cdRef.markForCheck();
        },
        () => {
          this.locals.projectId = null;
          this.cdRef.markForCheck();
        },
      );
    }
  }

  onProjectSelectionSave({ type, project }:{ type:PrincipalType, project:ProjectResource|null }):void {
    this.type = type;
    this.project = project;
    this.goTo(Steps.Principal);
  }

  onPrincipalSave({
    principalData, isAlreadyMember, role, message,
  }:{ principalData:PrincipalData, isAlreadyMember:boolean, role:RoleResource, message:string }):void {
    this.principalData = principalData;
    this.role = role;
    this.message = message;
    if (isAlreadyMember) {
      return this.closeWithPrincipal();
    }

    return this.goTo(Steps.Summary);
  }

  onSuccessfulSubmission($event:{ principal:HalResource }):void {
    if (this.principalData.principal !== $event.principal && this.type === PrincipalType.User) {
      this.createdNewPrincipal = true;
    }
    this.principalData.principal = $event.principal;
    this.goTo(Steps.Success);
  }

  goTo(step:Steps):void {
    this.step = step;
  }

  closeWithPrincipal():void {
    this.data = this.principalData.principal;
    this.closeMe();
  }
}
