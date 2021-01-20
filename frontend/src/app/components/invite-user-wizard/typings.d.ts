interface IUserWizardStep {
  type:string;
  label?:Function;
  summaryLabel?:string;
  bindLabel?:string;
  formControlName?:string;
  apiCallback?:Function;
  description?:Function;
  nextButtonText?:string;
  previousButtonText?:string;
  showInviteUserByEmail?:boolean;
}