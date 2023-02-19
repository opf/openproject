import { HttpErrorResponse } from '@angular/common/http';
import {
  IHalOptionalTitledLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';

export interface IEnterpriseData {
  id?:string;
  company:string;
  first_name:string;
  last_name:string;
  email:string;
  domain:string;
  general_consent?:boolean;
  newsletter_consent?:boolean;
}

export interface IEnterpriseTrial {
  trialLink?:string;
  resendLink?:string;
  modalOpen:boolean;
  confirmed:boolean;
  cancelled:boolean;
  status?:'mailSubmitted'|'startTrial';
  error?:HttpErrorResponse;
  emailInvalid:boolean;

  data?:IEnterpriseData;
}

export interface EnterpriseTrialHalResource {
  _links:IHalResourceLinks;
}

export interface EnterpriseTrialErrorHalResource {
  identifier:string;
  message?:string;
  description?:string;
  _links:{
    self:IHalOptionalTitledLink;
    resend:IHalOptionalTitledLink;
  };
}
