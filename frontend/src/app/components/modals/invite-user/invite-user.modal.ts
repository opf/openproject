import {ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import * as URI from 'urijs';
import {HttpClient} from '@angular/common/http';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Observable} from 'rxjs';

@Component({
  templateUrl: './invite-user.modal.html',
  styleUrls: ['./invite-user.modal.sass'],
  changeDetection: ChangeDetectionStrategy.onPush,
})
export class InviteUserModal extends OpModalComponent implements OnInit {
  /* Close on escape? */
  public closeOnEscape = true;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  public text = {
    title: this.I18n.t('js.label_export'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

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
