import {InsertMode} from '../wp-attachments-formattable.enums';
import {IApplyAttachmentMarkup} from '../wp-attachments-formattable.interfaces';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {MarkupModel} from './markup-model';
import {WorkPackageCacheService} from '../../work-package-cache.service';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageChangeset} from '../../../wp-edit-form/work-package-changeset';
import {Injector} from '@angular/core';

export class WorkPackageFieldModel implements IApplyAttachmentMarkup {
  public contentToInsert:string;

  constructor(protected workPackage:WorkPackageResourceInterface,
              protected attribute:string,
              protected markupModel:MarkupModel) {


    const formattable = workPackage[attribute];
    this.contentToInsert = _.get(formattable, 'raw') as string || '';
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
    let value = this.workPackage[this.attribute] || { raw: '', html: '' };
    value.raw = this.contentToInsert;

    // Temporarily get the ng2 injector since
    const wpCacheService = window.ng2Injector.get(WorkPackageCacheService);
    const changeset = new WorkPackageChangeset(window.ng2Injector, this.workPackage);
    changeset.setValue(this.attribute, value);

    changeset
      .save();
  }
}
