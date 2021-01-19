import {ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import * as URI from 'urijs';
import {HttpClient} from '@angular/common/http';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Observable} from 'rxjs';

@Component({
  templateUrl: './invite-user.component.html',
  styleUrls: ['./invite-user.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InviteUserModalComponent extends OpModalComponent implements OnInit {
  private steps = [
    'project-selection',
    'username',
    'role',
    'message',
    'summary',
    'success',
  ];
  private stepIndex = 0;

  /* Close on escape? */
  public closeOnEscape = true;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  public type:string|null = null;
  public project = null;
  public principal = null;
  public role = null;
  public message = '';

  public get step() {
    return this.steps[this.stepIndex];
  }

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef,
              readonly httpClient:HttpClient) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
  }

  onProjectSelectionSave() {
    console.log('select project');
  }

  back() {
    this.stepIndex = Math.max(this.stepIndex - 1, 0);
  }
}
