import { Injectable } from "@angular/core";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HttpClient, HttpErrorResponse, HttpHeaders } from "@angular/common/http";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { FormGroup } from "@angular/forms";
import { input } from "reactivestates";

export interface EnterpriseTrialData {
  id?:string;
  company:string;
  first_name:string;
  last_name:string;
  email:string;
  domain:string;
  general_consent?:boolean;
  newsletter_consent?:boolean;
}

@Injectable()
export class EnterpriseTrialService {
  // user data needs to be sync in ee-active-trial.component.ts
  userData$ = input<EnterpriseTrialData>();

  public readonly baseUrlAugur:string;
  public readonly tokenVersion:string;

  public trialLink:string;
  public resendLink:string;

  public modalOpen = false;
  public confirmed:boolean;
  public cancelled = false;
  public status:'mailSubmitted'|'startTrial'|undefined;
  public error:HttpErrorResponse|undefined;
  public emailInvalid = false;
  public text = {
    invalid_email: this.I18n.t('js.admin.enterprise.trial.form.invalid_email'),
    taken_email: this.I18n.t('js.admin.enterprise.trial.form.taken_email'),
    taken_domain: this.I18n.t('js.admin.enterprise.trial.form.taken_domain'),
  };

  constructor(readonly I18n:I18nService,
              protected http:HttpClient,
              readonly pathHelper:PathHelperService,
              protected notificationsService:NotificationsService) {
    const gon = (window as any).gon;
    this.baseUrlAugur = gon.augur_url;
    this.tokenVersion = gon.token_version;

    if ((window as any).gon.ee_trial_key) {
      this.setMailSubmittedStatus();
    }
  }

  // send POST request with form object
  // receive an enterprise trial link to access a token
  public sendForm(form:FormGroup) {
    const request = { ...form.value, token_version: this.tokenVersion };
    this.http.post(this.baseUrlAugur + '/public/v1/trials', request)
      .toPromise()
      .then((enterpriseTrial:any) => {
        this.userData$.putValue(form.value);
        this.cancelled = false;

        this.trialLink = enterpriseTrial._links.self.href;
        this.saveTrialKey(this.trialLink);

        this.retryConfirmation();
      })
      .catch((error:HttpErrorResponse) => {
        // mail is invalid or user already created a trial
        if (error.status === 422 || error.status === 400) {
          this.error = error;
        } else {
          this.notificationsService.addWarning(error.error.description || I18n.t('js.error.internal'));
        }
      });
  }

  // get a token from the trial link if user confirmed mail
  public getToken() {
    // 2) GET /public/v1/trials/:id
    this.http
      .get<any>(this.trialLink)
      .toPromise()
      .then(async (res:any) => {
        // show confirmed status and enable continue btn
        this.confirmed = true;

        // returns token if mail was confirmed
        // -> if token is new (token_retrieved: false) save token in backend
        if (!res.token_retrieved) {
          await this.saveToken(res.token);
        }
      })
      .catch((error:HttpErrorResponse) => {
        // returns error 422 while waiting of confirmation
        if (error.status === 422 && error.error.identifier === 'waiting_for_email_verification') {
          // get resend button link
          this.resendLink = error.error._links.resend.href;
          // save a key for the requested trial
          if (!this.status || this.cancelled) { // only do it once
            this.saveTrialKey(this.resendLink);
          }
          // open next modal window -> status waiting
          this.setMailSubmittedStatus();
          this.confirmed = false;
        } else if (_.get(error, 'error._type') === 'Error') {
          this.notificationsService.addError(error.error.message);
        } else {
          this.notificationsService.addError(error.error || I18n.t('js.error.internal'));
        }
      });
  }

  // save a part of the resend link in db
  // which allows to remember if a user has already requested a trial token
  // and to ask for the corresponding user data saved in Augur
  private saveTrialKey(resendlink:string) {
    // extract token from resend link
    const trialKey = resendlink.split('/')[6];
    return this.http.post(
      this.pathHelper.appBasePath + '/admin/enterprise/save_trial_key',
      { trial_key: trialKey },
      { withCredentials: true }
    )
      .toPromise()
      .catch((e:any) => {
        this.notificationsService.addError(e.error.message || e.message || e);
      });
  }

  // save received token in controller
  private saveToken(token:string) {
    return this.http.post(
      this.pathHelper.appBasePath + '/admin/enterprise',
      { enterprise_token: { encoded_token: token } },
      { withCredentials: true }
    )
      .toPromise()
      .then(() => {
        // load page if mail was confirmed and modal window is not open
        if (!this.modalOpen) {
          setTimeout(() => { // display confirmed status before reloading
            window.location.reload();
          }, 500);
        }
      })
      .catch((error:HttpErrorResponse) => {
        // Delete the trial key as the token could not be saved and thus something is wrong with the token.
        // Without this deletion, we run into an endless loop of an confirmed mail, but no saved token.
        this.http
          .delete(
            this.pathHelper.api.v3.apiV3Base + '/admin/enterprise/delete_trial_key',
            { withCredentials: true }
          )
          .toPromise();

        this.notificationsService.addError(error.error.description || I18n.t('js.error.internal'));
      });
  }

  // retry request while waiting for mail confirmation
  public retryConfirmation(delay = 5000, retries = 60) {
    if (this.cancelled || this.confirmed) {
      return;
    } else if (retries === 0) {
      this.cancelled = true;
    } else {
      this.getToken();
      setTimeout(() => {
        this.retryConfirmation(delay, retries - 1);
      }, delay);
    }
  }

  public setStartTrialStatus() {
    this.status = 'startTrial';
  }

  public setMailSubmittedStatus() {
    this.status = 'mailSubmitted';
  }

  public get trialStarted():boolean {
    return this.status === 'startTrial';
  }

  public get mailSubmitted():boolean {
    return this.status === 'mailSubmitted';
  }

  public get domainTaken():boolean {
    return this.error ? this.error.error.identifier === 'domain_taken' : false;
  }

  public get emailTaken():boolean {
    return this.error ? this.error.error.identifier === 'user_already_created_trial' : false;
  }

  public get emailError():boolean {
    if (this.emailInvalid) {
      return true;
    } else if (this.error) {
      return this.emailTaken;
    } else {
      return false;
    }
  }

  public get errorMsg() {
    let error = '';
    if (this.emailInvalid) {
      error = this.text.invalid_email;
    } else if (this.domainTaken) {
      error = this.text.taken_domain;
    } else if (this.emailTaken) {
      error = this.text.taken_email;
    }

    return error;
  }
}
