import {IApplyAttachmentMarkup} from './wp-attachments-formattable.interfaces';
import {InsertMode} from './wp-attachments-formattable.enums';
import {
  WorkPackageResourceInterface
} from '../../api/api-v3/hal-resources/work-package-resource.service';
import IAugmentedJQuery = angular.IAugmentedJQuery;

export class EditorModel implements IApplyAttachmentMarkup {
  private currentCaretPosition:number;
  public contentToInsert:string = '';

  constructor(protected textarea:IAugmentedJQuery, protected markupModel:MarkupModel) {
    this.setCaretPosition();
  }

  public insertWebLink(url:string, insertMode:InsertMode = InsertMode.LINK):void {
    this.contentToInsert = this.markupModel.createMarkup(url, insertMode);
  }

  public insertAttachmentLink(url:string,
                              insertMode:InsertMode = InsertMode.ATTACHMENT,
                              addLineBreak?:boolean):void {
    this.contentToInsert = (addLineBreak) ?
    this.contentToInsert + this.markupModel.createMarkup(url, insertMode, addLineBreak) :
      this.markupModel.createMarkup(url, insertMode, addLineBreak);
  }

  private setCaretPosition():void {
    this.currentCaretPosition = (this.textarea[0] as HTMLTextAreaElement).selectionStart;
  }

  public save():void {
    let insertPosition = this.normalizeInputAndGetInsertPosition();
    let currentValue = this.textarea.val();

    let newValue = currentValue.substring(0, insertPosition) +
                   this.contentToInsert +
                   currentValue.substring(this.currentCaretPosition, currentValue.length);

    this.textarea.val(newValue).change();
  }

  /*
   * Assure that no whitespace is left before the inlined image as whitespaces will lead to the image being wrapped in a
   * <pre><code>image</code><pre> block
   * Removes two sources of whitespace:
   *  * The whitespace prepended to the content to insert
   *  * Whitespace added by the user on a newline
   */

  private normalizeInputAndGetInsertPosition() {
    let currentValue = this.textarea.val();
    let newlineMatch = currentValue.substring(0, this.currentCaretPosition).match(/\n *$/);
    let newlineIndex = newlineMatch && newlineMatch.index || 0;
    let whitespacesBeforeCaret = this.currentCaretPosition - newlineIndex;

    if (whitespacesBeforeCaret > 0) {
      this.contentToInsert = this.contentToInsert.substring(1, this.contentToInsert.length);
    }

    return (newlineIndex && newlineIndex + 1) || this.currentCaretPosition;
  }
}

export class MarkupModel {
  public createMarkup(insertUrl:string, insertMode:InsertMode, addLineBreak:boolean = false):string {
    if (angular.isUndefined((insertUrl))) {
      return '';
    }

    var markup:string = ' ';

    switch (insertMode) {
      case InsertMode.ATTACHMENT:
        markup += 'attachment:' + insertUrl.split('/').pop();
        break;
      case InsertMode.DELAYED_ATTACHMENT:
        markup += 'attachment:' + insertUrl;
        break;
      case InsertMode.INLINE:
        markup += '!' + insertUrl + '!';
        break;
      case InsertMode.LINK:
        markup += insertUrl;
        break;
    }

    if (addLineBreak) {
      markup += '\r\n';
    }

    return markup;
  }
}

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

  public filesAreValidForUploading():boolean {
    return true;
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

export class FieldModel implements IApplyAttachmentMarkup {
  public contentToInsert:string;

  constructor(protected workPackage:WorkPackageResourceInterface, protected markupModel:MarkupModel) {
    this.contentToInsert = workPackage.description.raw || '';
  }


  private addInitialLineBreak():string {
    return (this.contentToInsert.length > 0) ? '\r\n' : '';
  }

  public insertAttachmentLink(url:string, insertMode:InsertMode, addLineBreak?:boolean):void {
    this.contentToInsert += this.addInitialLineBreak() + this.markupModel.createMarkup(url, insertMode, false);
  }

  public insertWebLink(url:string, insertMode:InsertMode):void {
    this.contentToInsert += this.addInitialLineBreak() + this.markupModel.createMarkup(url, insertMode, false);
  }

  public save():void {
    this.workPackage.description.raw = this.contentToInsert;
    this.workPackage.save();
  }
}

