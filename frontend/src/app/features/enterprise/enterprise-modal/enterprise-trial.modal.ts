//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  Input,
  ViewChild,
} from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { EETrialFormComponent } from 'core-app/features/enterprise/enterprise-modal/enterprise-trial-form/ee-trial-form.component';
import { EnterpriseTrialService } from 'core-app/features/enterprise/enterprise-trial.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export const eeOnboardingVideoURL = 'https://www.youtube.com/embed/zLMSydhFSkw?autoplay=1';

@Component({
  selector: 'enterprise-trial-modal',
  templateUrl: './enterprise-trial.modal.html',
  styleUrls: ['./enterprise-trial.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EnterpriseTrialModalComponent extends OpModalComponent implements AfterViewInit {
  @ViewChild(EETrialFormComponent, { static: false }) formComponent:EETrialFormComponent;

  @Input() public opReferrer:string;

  public trialForm:UntypedFormGroup;

  public trustedEEVideoURL:SafeResourceUrl;

  public text = {
    button_submit: this.I18n.t('js.modals.button_submit'),
    button_cancel: this.I18n.t('js.modals.button_cancel'),
    button_continue: this.I18n.t('js.button_continue'),
    close_popup: this.I18n.t('js.close_popup_title'),
    heading_confirmation: this.I18n.t('js.admin.enterprise.trial.confirmation'),
    heading_next_steps: this.I18n.t('js.admin.enterprise.trial.next_steps'),
    heading_test_ee: this.I18n.t('js.admin.enterprise.trial.test_ee'),
    quick_overview: this.I18n.t('js.admin.enterprise.trial.quick_overview'),
  };

  headerText$:Observable<string> = this
    .eeTrialService
    .observe$
    .pipe(
      map(({ status }) => {
        if (status === 'mailSubmitted') {
          return this.text.heading_confirmation;
        }

        if (status === 'startTrial') {
          return this.text.heading_next_steps;
        }

        return this.text.heading_test_ee;
      }),
    );

  showState$ = this
    .eeTrialService
    .observe$
    .pipe(
      map(({ status, cancelled }) => {
        if (!status || cancelled) {
          return 'trial-form';
        }
        if (status === 'mailSubmitted' && !cancelled) {
          return 'trial-waiting';
        }

        return 'overview';
      }),
    );

  constructor(readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly domSanitizer:DomSanitizer,
    public eeTrialService:EnterpriseTrialService) {
    super(locals, cdRef, elementRef);
    this.trustedEEVideoURL = this.trustedURL(eeOnboardingVideoURL);
  }

  ngAfterViewInit():void {
    this.trialForm = this.formComponent.trialForm;
  }

  // checks if form is valid and submits it
  public onSubmit():void {
    if (this.trialForm.valid) {
      this.trialForm.addControl('_type', new UntypedFormControl('enterprise-trial'));
      void this.eeTrialService.sendForm(this.trialForm);
    }
  }

  public startEnterpriseTrial():void {
    // open onboarding modal screen
    this.eeTrialService.setStartTrialStatus();
  }

  public closeModal(event:Event):void {
    this.closeMe(event);

    const { status, confirmed } = this.eeTrialService.current;
    // refresh page to show enterprise trial
    if (status === 'startTrial' || confirmed) {
      window.location.reload();
    } else if (status === 'mailSubmitted') {
      window.location.reload();
      return;
    }

    this.eeTrialService.store.update({ modalOpen: false });
  }

  public trustedURL(url:string):SafeResourceUrl {
    return this.domSanitizer.bypassSecurityTrustResourceUrl(url);
  }
}
