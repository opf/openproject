import {Injectable} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HttpClient, HttpErrorResponse} from "@angular/common/http";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {FormBuilder, FormGroup} from "@angular/forms";

export const baseUrlAugur = 'https://augur.openproject-edge.com';

@Injectable()
export class EnterpriseTrialService {
  public userData:{subscriber:string, email:string};

  public trialLink:string;
  public resendLink:string;

  public modalOpen = false;
  public confirmed:boolean;
  public cancelled = false;
  public status:'mailSubmitted'|'startTrial'|undefined;
  public errorMsg:string|undefined;

  // retry confirmation
  public delay = 5000; // wait 5s until next request
  public retries = 60; // keep trying for 5 minutes

  constructor(readonly I18n:I18nService,
              protected http:HttpClient,
              readonly pathHelper:PathHelperService,
              protected notificationsService:NotificationsService,
              readonly formBuilder:FormBuilder) {
    if ((window as any).gon) {
      this.status = 'mailSubmitted';
    }
  }

  // send POST request with form object
  // receive an enterprise trial link to access a token
  public sendForm(form:FormGroup) {
    this.userData = {
      subscriber: form.value.first_name + ' ' + form.value.last_name,
      email: form.value.email
    };
    this.cancelled = false;
    // POST /public/v1/trials/
    this.http.post(baseUrlAugur + '/public/v1/trials', form.value)
      .toPromise()
      .then((enterpriseTrial:any) => {
        this.trialLink = enterpriseTrial._links.self.href;

        this.retryConfirmation(this.delay, this.retries);
      })
      .catch((error:HttpErrorResponse) => {
        // mail is invalid or user already created a trial
        if (error.status === 422 || error.status === 400) {
          this.errorMsg = error.error.description;
        } else {
          // 500 -> internal error occured
          this.notificationsService.addWarning(error.error.description || I18n.t('js.error.internal'));
        }
      });
  }

  // get a token from the trial link if user confirmed mail
  private getToken() {
    // 2) GET /public/v1/trials/:id
    this.http
      .get<any>(this.trialLink)
      .toPromise()
      .then((res:any) => {
        // show confirmed status and enable continue btn
        this.confirmed = true;

        // returns token if mail was confirmed
        // -> if token is new (token_retrieved: false) save token in backend
        if (!res.token_retrieved) {
          this.saveToken(res.token);
        }

        // load page if mail was confirmed and modal window is not open
        if (!this.modalOpen) {
          setTimeout(() => { // display confirmed status before reloading
            window.location.reload();
          }, 500);
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
          this.status = 'mailSubmitted';
          this.confirmed = false;
        } else if (_.get(error, 'error._type') === 'Error') {
          this.notificationsService.addError(error.error.message);
        } else {
          // backend returned an unsuccessful response code
          this.notificationsService.addError(error.error || I18n.t('js.error.internal'));
        }
      });
  }

  // save a part of the resend link in db
  // which allows to remember if a user has already requested a trial token
  // and to ask for the corresponding user data saved in Augur
  private saveTrialKey(resendlink:string) {
    // extract token from resend link
    let trialKey = resendlink.split('/')[6];
    // save requested token
    return this.http.post(
      this.pathHelper.api.v3.appBasePath + '/admin/enterprise/save_trial_key',
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
    // POST /admin/enterprise (params[:enterprise_token][:encoded_token])
    this.http.post(
      this.pathHelper.api.v3.appBasePath + '/admin/enterprise',
      { enterprise_token: { encoded_token: token } },
      { withCredentials: true }
      )
      .toPromise()
      .catch((error:HttpErrorResponse) => {
        this.notificationsService.addError(error.error.description || I18n.t('js.error.internal'));
      });
  }

  // retry request while waiting for mail confirmation
  public retryConfirmation(delay:number, retries:number) {
    if (this.cancelled || this.confirmed) {
      // stop if action was cancelled or confirmation link was clicked
      return;
    } else if (retries === 0) {
      // action timed out -> show message
      this.cancelled = true;
    } else {
      // retry as long as limit isn't reached
      this.getToken();
      setTimeout( () => {
        this.retryConfirmation(delay, retries - 1);
      }, delay);
    }
  }

  public setStartTrialStatus() {
    this.status = 'startTrial';
  }

  public get trialStarted():boolean {
    return this.status === 'startTrial';
  }

  public get mailSubmitted():boolean {
    return this.status === 'mailSubmitted';
  }
}
