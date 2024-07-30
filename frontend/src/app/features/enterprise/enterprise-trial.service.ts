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

import { Injectable } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Query } from '@datorama/akita';
import { filter, map, shareReplay } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { EXTERNAL_REQUEST_HEADER } from 'core-app/features/hal/http/openproject-header-interceptor';
import { EnterpriseTrialStore } from 'core-app/features/enterprise/enterprise-trial.store';
import { GonService } from 'core-app/core/gon/gon.service';
import { EnterpriseTrialErrorHalResource, EnterpriseTrialHalResource, IEnterpriseData, IEnterpriseTrial } from 'core-app/features/enterprise/enterprise-trial.model';
import isDefinedEntity from 'core-app/core/state/is-defined-entity';

@Injectable()
export class EnterpriseTrialService {
  readonly store = new EnterpriseTrialStore();

  private query = new Query(this.store);

  confirmed$ = this.query.select('confirmed');

  cancelled$ = this.query.select('cancelled');

  status$ = this.query.select('status');

  observe$ = this.query.select();

  userData$ = this.query
    .select('data')
    .pipe(filter(isDefinedEntity));

  emailError$ = this
    .query
    .select()
    .pipe(
      map(({ error, emailInvalid }) => {
        if (emailInvalid) {
          return this.text.invalid_email;
        }

        const errorResponse = error?.error as { identifier?:string };
        if (error && errorResponse.identifier === 'user_already_created_trial') {
          return this.text.taken_email;
        }
        return null;
      }),
      shareReplay(1),
    );

  domainTaken$ = this
    .query
    .select()
    .pipe(
      map(({ error }) => {
        const errorResponse = error?.error as { identifier?:string };
        if (error && errorResponse.identifier === 'domain_taken') {
          return this.text.taken_domain;
        }
        return null;
      }),
      shareReplay(1),
    );

  public readonly baseUrlAugur:string;

  public readonly tokenVersion:string;

  public text = {
    invalid_email: this.I18n.t('js.admin.enterprise.trial.form.invalid_email'),
    taken_email: this.I18n.t('js.admin.enterprise.trial.form.taken_email'),
    taken_domain: this.I18n.t('js.admin.enterprise.trial.form.taken_domain'),
  };

  constructor(
    readonly I18n:I18nService,
    protected http:HttpClient,
    readonly pathHelper:PathHelperService,
    protected toastService:ToastService,
    readonly Gon:GonService,
  ) {
    this.baseUrlAugur = this.Gon.get('augur_url') as string;
    this.tokenVersion = this.Gon.get('token_version') as string;

    if (this.Gon.get('ee_trial_key')) {
      this.setMailSubmittedStatus();
    }
  }

  // send POST request with form object
  // receive an enterprise trial link to access a token
  public sendForm(form:UntypedFormGroup):Promise<unknown> {
    const request:unknown = { ...form.value, token_version: this.tokenVersion };
    return this.http
      .post(
        `${this.baseUrlAugur}/public/v1/trials`,
        request,
        {
          headers: {
            [EXTERNAL_REQUEST_HEADER]: 'true',
          },
        },
      )
      .toPromise()
      .then((enterpriseTrial:EnterpriseTrialHalResource) => {
        const trialLink = enterpriseTrial._links.self.href;
        const data = form.value as IEnterpriseData;

        this.store.update({
          trialLink,
          data,
          cancelled: false,
        });

        void this.saveTrialKey(trialLink);
        this.retryConfirmation();
      })
      .catch((error:HttpErrorResponse) => {
        // mail is invalid or user already created a trial
        if (error.status === 422 || error.status === 400) {
          this.store.update({ error });
        } else {
          const description = (error.error as { description?:string }).description;
          this.toastService.addWarning(description || I18n.t('js.error.internal'));
        }
      });
  }

  // get a token from the trial link if user confirmed mail
  public getToken():void {
    // 2) GET /public/v1/trials/:id
    this.http.get(
      this.store.getValue().trialLink as string,
      {
        headers: {
          [EXTERNAL_REQUEST_HEADER]: 'true',
        },
      },
    )
      .toPromise()
      .then(async (res:{ token_retrieved?:boolean, token:string }) => {
        // show confirmed status and enable continue btn
        this.store.update({ confirmed: true });

        // returns token if mail was confirmed
        // -> if token is new (token_retrieved: false) save token in backend
        if (!res.token_retrieved) {
          await this.saveToken(res.token);
        }
      })
      .catch((error:HttpErrorResponse) => {
        const errorResponse = error.error as EnterpriseTrialErrorHalResource;
        // returns error 422 while waiting of confirmation
        if (error.status === 422 && errorResponse.identifier === 'waiting_for_email_verification') {
          // get resend button link
          const resendLink = errorResponse._links.resend.href;
          this.store.update({ resendLink });

          const { status, cancelled } = this.store.getValue();

          // save a key for the requested trial
          if (!status || cancelled) { // only do it once
            void this.saveTrialKey(resendLink);
          }
          // open next modal window -> status waiting
          this.setMailSubmittedStatus();
          this.store.update({ confirmed: false });
        } else if (errorResponse?.message) {
          this.toastService.addError(errorResponse.message);
        } else {
          this.toastService.addError(error.error || I18n.t('js.error.internal'));
        }
      });
  }

  // save a part of the resend link in db
  // which allows to remember if a user has already requested a trial token
  // and to ask for the corresponding user data saved in Augur
  private saveTrialKey(resendlink:string):Promise<unknown> {
    // extract token from resend link
    const trialKey = resendlink.split('/')[6];
    return this.http.post(
      `${this.pathHelper.appBasePath}/admin/enterprise/save_trial_key`,
      { trial_key: trialKey },
      { withCredentials: true },
    )
      .toPromise()
      .catch((e:HttpErrorResponse) => {
        const errorResponse = e.error as EnterpriseTrialErrorHalResource;
        this.toastService.addError(errorResponse.message || e.message || e);
      });
  }

  // save received token in controller
  private saveToken(token:string) {
    return this.http.post(
      `${this.pathHelper.appBasePath}/admin/enterprise`,
      { enterprise_token: { encoded_token: token } },
      { withCredentials: true },
    )
      .toPromise()
      .then(() => {
        const { modalOpen } = this.store.getValue();
        // load page if mail was confirmed and modal window is not open
        if (!modalOpen) {
          setTimeout(() => { // display confirmed status before reloading
            window.location.reload();
          }, 500);
        }
      })
      .catch((error:HttpErrorResponse) => {
        // Delete the trial key as the token could not be saved and thus something is wrong with the token.
        // Without this deletion, we run into an endless loop of an confirmed mail, but no saved token.
        void this.http
          .delete(
            `${this.pathHelper.api.v3.apiV3Base}/admin/enterprise/delete_trial_key`,
            { withCredentials: true },
          )
          .toPromise();

        const errorResponse = error.error as EnterpriseTrialErrorHalResource;
        this.toastService.addError(errorResponse.description || I18n.t('js.error.internal'));
      });
  }

  // retry request while waiting for mail confirmation
  public retryConfirmation(delay = 5000, retries = 60):void {
    const { cancelled, confirmed } = this.store.getValue();

    if (cancelled || confirmed) {
      // no need to retry
      return;
    }

    if (retries === 0) {
      this.store.update({ cancelled: true });
    } else {
      this.getToken();
      setTimeout(() => {
        this.retryConfirmation(delay, retries - 1);
      }, delay);
    }
  }

  public setStartTrialStatus():void {
    this.store.update({ status: 'startTrial' });
  }

  public setMailSubmittedStatus():void {
    this.store.update({ status: 'mailSubmitted' });
  }

  public get current():IEnterpriseTrial {
    return this.store.getValue();
  }
}
