interface IUserWizardStep {
  name:string;
  fields:IUserWizardStepField[];
  nextButtonText?:string;
  previousButtonText?:string;
  showInviteUserByEmail?:boolean;
  action?:Function;
}

interface IUserWizardStepField {
  type:string;
  label?:Function;
  bindLabel?:string;
  formControlName?:string;
  options?:any[];
  apiCallback?:Function;
  description?:Function;
  link?:{
    text:string;
    href:string;
  };
  invalidText?:string;
}

interface IUserWizardSelectData {
  name:string;
  id:string;
  email:string;
  disabled:boolean;
  _type?:string;
}