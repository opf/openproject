import IAugmentedJQuery = angular.IAugmentedJQuery;
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class PasteModel {
  public files:File[] = [];

  constructor(protected dataTransfer:DataTransfer) {
    this.extractFiles(dataTransfer.files);
  }

  private extractFiles(items:FileList):void {
    if (!items) {
      return;
    }

    for (let i = 0; i < items.length; i++) {
      if (items[i].type.indexOf("image") !== -1) {
        //image
        this.files.push(items[i]);
      }
    }
  }
}
