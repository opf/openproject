import IAugmentedJQuery = angular.IAugmentedJQuery;

export class SingleAttachmentModel {
  protected imageFileExtensions:Array<string> = ['jpeg', 'jpg', 'gif', 'bmp', 'png'];

  public fileExtension:string;
  public fileName:string;
  public isAnImage:boolean;
  public url:string;


  constructor(protected attachment:any) {
    if (angular.isDefined(attachment)) {
      this.fileName = attachment.fileName || attachment.name;
      this.fileExtension = (this.fileName.split('.') as any[]).pop().toLowerCase();
      this.isAnImage = this.imageFileExtensions.indexOf(this.fileExtension) > -1;
      this.url = angular.isDefined(attachment.downloadLocation) ? attachment.downloadLocation.$link.href : '';
    }
  }

}

