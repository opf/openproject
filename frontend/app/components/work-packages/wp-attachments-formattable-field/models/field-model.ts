import {InsertMode} from '../wp-attachments-formattable.enums';
import {IApplyAttachmentMarkup} from '../wp-attachments-formattable.interfaces';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {MarkupModel} from './markup-model';
import IAugmentedJQuery = angular.IAugmentedJQuery;

export class FieldModel implements IApplyAttachmentMarkup {
  public contentToInsert:string;

  constructor(protected workPackage:WorkPackageResourceInterface, protected markupModel:MarkupModel) {
    this.contentToInsert = workPackage.description.raw || '';
  }

  private addInitialLineBreak():string {
    return (this.contentToInsert.length > 0) ? '\r\n' : '';
  }

  public insertAttachmentLink(url:string, insertMode:InsertMode, addLineBreak?:boolean):void {
    this.contentToInsert += this.addInitialLineBreak() + this.markupModel.createMarkup(url,
        insertMode,
        false);
  }

  public insertWebLink(url:string, insertMode:InsertMode):void {
    this.contentToInsert += this.addInitialLineBreak() + this.markupModel.createMarkup(url,
        insertMode,
        false);
  }

  public save():void {
    this.workPackage.description.raw = this.contentToInsert;
    this.workPackage.save();
  }
}
