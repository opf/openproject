import IAugmentedJQuery = angular.IAugmentedJQuery;
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class DropModel {
  public files:File[];
  public filesCount:number;
  public isUpload:boolean;
  public isDelayedUpload:boolean;
  public isWebLink:boolean;
  public webLinkUrl:string;

  protected config:any = {
    imageFileTypes: ['jpg', 'jpeg', 'gif', 'png'],
    maximumAttachmentFileSize: 0, // initialized during init process from ConfigurationService
  };

  constructor(protected $location:ng.ILocationService,
              protected dataTransfer:any,
              protected workPackage:WorkPackageResourceInterface) {
    this.files = <File[]>dataTransfer.files;
    this.filesCount = this.files.length;
    this.isUpload = this._isUpload(dataTransfer);
    this.isDelayedUpload = this.workPackage.isNew;
    this.isWebLink = !this.isUpload;
    this.webLinkUrl = dataTransfer.getData('URL');
  }

  public isWebImage():boolean {
    if (angular.isDefined(this.webLinkUrl)) {
      const ext = (this.webLinkUrl.split('.') as any[]).pop();
      return (this.config.imageFileTypes.indexOf(ext.toLowerCase()) > -1);
    }

    return false;
  }

  public isAttachmentOfCurrentWp():boolean {
    if (this.isWebLink) {

      // weblink does not point to our server, so it can't be an attachment
      if (!(this.webLinkUrl.indexOf(this.$location.host()) > -1)) {
        return false;
      }

      var isAttachment:boolean = false;

      this.workPackage.attachments.elements.forEach(attachment => {
        if (this.webLinkUrl.indexOf(attachment.href as string) > -1) {
          isAttachment = true;
          return;
        }
      });
      return isAttachment;
    }

    return false;
  }

  public removeHostInformationFromUrl():string {
    return this.webLinkUrl.replace(window.location.origin, '');
  }

  protected _isUpload(dt:DataTransfer):boolean {
    if (dt.types && this.filesCount > 0) {
      for (let i = 0; i < dt.types.length; i++) {
        if (dt.types[i] === 'Files') {
          return true;
        }
      }
    }
    return false;
  }
}
