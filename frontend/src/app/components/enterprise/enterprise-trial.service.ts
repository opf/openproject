import {Injectable} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HttpClient, HttpErrorResponse} from "@angular/common/http";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {FormGroup} from "@angular/forms";


@Injectable()
export class EnterpriseTrialService {
  public trialForm:FormGroup;
  public baseUrlAugur = 'https://augur.openproject-edge.com';
  public trialLink:string;
  public resendLink:string;

  public confirmed:boolean;
  public cancelled = false;
  public status:string|undefined;
  public errorMsg:string|undefined;

  constructor(readonly I18n:I18nService,
              protected http:HttpClient,
              readonly pathHelper:PathHelperService,
              protected notificationsService:NotificationsService) {
  }

  // sends POST request with form object
  // receives an enterprise trial link to access a token
  public sendForm(form:FormGroup) {
    this.trialForm = form;
    const delay = 5000; // wait 5s until next request
    const retries = 60; // keep trying for 5 minutes

    // POST /public/v1/trials/
    this.http.post(this.baseUrlAugur + '/public/v1/trials', form)
      .toPromise()
      .then((enterpriseTrial:any) => {
        console.log('Form successfully send: ', this.trialForm);
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
        // returns token if mail was confirmed -> save token in backend
        console.log('res.token_retrieved: ', res.token_retrieved);
        this.saveToken(res.token);
      })
      .catch((error:HttpErrorResponse) => {
        // returns error 422 while waiting of confirmation
        if (error.status === 422 && error.error.identifier === 'waiting_for_email_verification') {
          // open next modal window -> status waiting
          this.status = 'mailSubmitted';
          this.confirmed = false;

          // get resend button link
          this.resendLink = error.error._links.resend.href;
        } else if (_.get(error, 'error._type') === 'Error') {
          this.notificationsService.addWarning(error.error.message);
        } else {
          // backend returned an unsuccessful response code
          this.notificationsService.addWarning(error.error);
        }
      });
  }

  // saves received token in controller
  private saveToken(token:string) {
    // POST /admin/enterprise (params[:enterprise_token][:encoded_token])
    // -> if token is new (token_retrieved: false) save token in ruby controller
    this.http.post(this.pathHelper.api.v3.appBasePath + '/admin/enterprise', { enterprise_token: { encoded_token: token } }, { withCredentials: true })
      .toPromise()
      .then((res:any) => {
        console.log('saveToken() success: ', res);
      })
      .catch((error:HttpErrorResponse) => {
        console.log('saveToken() failed: ', error.error);
        this.notificationsService.addWarning(error.error.description || I18n.t('js.error.internal'));
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
        this.notificationsService.addSuccess('Mail has been resent. Please check your mails and click the confirmation link provided.');

        this.cancelled = false;
        this.retryConfirmation(5000, 60);
      })
      .catch((error:HttpErrorResponse) => {
        console.log('An Error occured: ', error);
        this.notificationsService.addWarning('Could not resend mail.');
      });
  }
}