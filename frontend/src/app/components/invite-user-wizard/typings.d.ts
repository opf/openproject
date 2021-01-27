interface IUserWizardStep {
  type:string;
  label?:Function;
  summaryLabel?:string;
  bindLabel?:string;
  formControlName?:string;
  apiCallback?:Function;
  description?:Function;
  link?:{
    text:string;
    href:string;
  };
  nextButtonText?:string;
  previousButtonText?:string;
  showInviteUserByEmail?:boolean;
  action?:Function;
}

interface IUserWizardSelectData {
  name:string;
  id:string;
  email:string;
  disabled:boolean;
  _type?:string;
}