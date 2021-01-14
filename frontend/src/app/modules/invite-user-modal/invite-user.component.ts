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
  /* Close on escape? */
  public closeOnEscape = true;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  public text = {
    title: this.I18n.t('js.invite_user_modal.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

  public type:string|null = null;
  public project = null;
  public user = null;
  public role = null;
  public message = '';
  public step = 'project';

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef,
              readonly httpClient:HttpClient) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
  }
}
