import {Injectable} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HttpClient, HttpErrorResponse} from "@angular/common/http";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {FormBuilder, FormControl, FormGroup} from "@angular/forms";


@Injectable()
export class EnterpriseTrialService {
  private localStorageKey = 'openProject-enterprise-trial';

  public text = {
    resend_success: this.I18n.t('js.admin.enterprise.trial.resend_success'),
    resend_warning: this.I18n.t('js.admin.enterprise.trial.resend_warning')
  };

  public savedUserData:any; // saved data in local storage
  public trialForm:FormGroup;
  public baseUrlAugur = 'https://augur.openproject-edge.com';
  public trialLink:string;
  public resendLink:string;

  public confirmed:boolean;
  public cancelled = false;
  public status:'mailSubmitted'|'startTrial'|undefined;
  public errorMsg:string|undefined;

  constructor(readonly I18n:I18nService,
              protected http:HttpClient,
              readonly pathHelper:PathHelperService,
              protected notificationsService:NotificationsService,
              readonly formBuilder:FormBuilder) {
    this.savedUserData = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    // user has already submitted a valid mail and received a confirmation link
    if (this.savedUserData) {
      this.savedUserData = JSON.parse(this.savedUserData);
      this.resendLink = this.savedUserData.resend_link;
      this.status = 'mailSubmitted';
    }
  }

  // sends POST request with form object
  // receives an enterprise trial link to access a token
  public sendForm(form:FormGroup) {
    this.trialForm = form;
    const delay = 5000; // wait 5s until next request
    const retries = 60; // keep trying for 5 minutes

    // POST /public/v1/trials/
    this.http.post(this.baseUrlAugur + '/public/v1/trials', form.value)
      .toPromise()
      .then((enterpriseTrial:any) => {
        this.trialLink = enterpriseTrial._links.self.href;

        this.retryConfirmation(delay, retries);
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

  // gets a token from the trial link if user confirmed mail
  private getToken() {
    // 2) GET /public/v1/trials/:id
    this.http
      .get<any>(this.baseUrlAugur + this.trialLink)
      .toPromise()
      .then((res:any) => {
        // show confirmed status and enable continue btn
        this.confirmed = true;

        // returns token if mail was confirmed
        // -> if token is new (token_retrieved: false) save token in backend
        if (!res.token_retrieved) {
          this.saveToken(res.token);
        }
      })
      .catch((error:HttpErrorResponse) => {
        // returns error 422 while waiting of confirmation
        if (error.status === 422 && error.error.identifier === 'waiting_for_email_verification') {
          // open next modal window -> status waiting
          this.status = 'mailSubmitted';
          this.confirmed = false;

          // get resend button link
          this.resendLink = error.error._links.resend.href;

          this.savedUserData = {
            'subscriber': this.trialForm.value.first_name + ' ' + this.trialForm.value.last_name,
            'email': this.trialForm.value.email,
            'resend_link': this.resendLink
          };
          window.OpenProject.guardedLocalStorage(this.localStorageKey, JSON.stringify(this.savedUserData));

        } else if (_.get(error, 'error._type') === 'Error') {
          this.notificationsService.addWarning(error.error.message);
        } else {
          // backend returned an unsuccessful response code
          this.notificationsService.addWarning(error.error || I18n.t('js.error.internal'));
        }
      });
  }

  // saves received token in controller
  private saveToken(token:string) {
    // POST /admin/enterprise (params[:enterprise_token][:encoded_token])
    this.http.post(this.pathHelper.api.v3.appBasePath + '/admin/enterprise', { enterprise_token: { encoded_token: token } }, { withCredentials: true })
      .toPromise()
      .then((res:any) => {
        window.localStorage.removeItem(this.localStorageKey);
      })
      .catch((error:HttpErrorResponse) => {
        this.notificationsService.addWarning(error.error || I18n.t('js.error.internal'));
      });
  }

  // retries request while waiting for mail confirmation
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

  // resends mail if resend link has been clicked
  public resendMail() {
    this.http.post(this.baseUrlAugur + this.resendLink, {})
      .toPromise()
      .then((enterpriseTrial:any) => {
        this.notificationsService.addSuccess(this.text.resend_success);

        this.cancelled = false;
        this.retryConfirmation(5000, 60);
      })
      .catch((error:HttpErrorResponse) => {
        this.notificationsService.addWarning(this.text.resend_warning);
      });
  }
}