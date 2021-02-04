import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import {OpModalLocalsMap} from 'core-app/modules/modal/modal.types';
import {OpModalComponent} from 'core-app/modules/modal/modal.component';
import {OpModalLocalsToken} from "core-app/modules/modal/modal.service";
import * as URI from 'urijs';
import {HttpClient} from '@angular/common/http';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Observable} from 'rxjs';

enum Steps {
  ProjectSelection,
  Principal,
  Role,
  Message,
  Summary,
  Success,
}

export enum PrincipalType {
  User = 'user',
  Placeholder = 'placeholder',
  Group = 'group',
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

  /* Close on escape? */
  public closeOnEscape = true;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  public type:PrincipalType|null = null;
  public project:any = null;
  public principal = null;
  public role = null;
  public message = '';

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
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

  onRoleSave({ role }:{ role:any }) {
    this.role = role;

    if (this.type === 'placeholder') {
      this.goTo(Steps.Summary);
    } else {
      this.goTo(Steps.Message);
    }
  }

  onMessageSave({ message }:{ message:string }) {
    this.message = message;
    this.goTo(Steps.Summary);
  }

  goTo(step:Steps) {
    this.step = step;
  }

  closeWithPrincipal() {
    this.closeMe();
  }
}
