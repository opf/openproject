import IAugmentedJQuery = angular.IAugmentedJQuery;
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class PasteModel {
  public files:File[] = [];

  constructor(protected dataTransfer:DataTransfer) {
    this.extractFiles(dataTransfer.files);

    // Try to extract files from dataTransfer.items
    // to support older versions of Chrome.
    if (this.files.length === 0) {
      this.extractItems(dataTransfer.items);
    }
  }

  private extractFiles(items:FileList):void {
    try {
      if (!items) {
        return;
      }

      for (let i = 0; i < items.length; i++) {
        if (items[i].type.indexOf('image') !== -1) {
          //image
          this.files.push(items[i]);
        }
      }
    } catch(e) {
      console.error('Failed to extract files from PasteEvent dataTransfer.files: ' + e);
    }
  }

  private extractItems(items:DataTransferItemList):void {
    try {
      if (!items) {
        return;
      }

      for (let i = 0; i < items.length; i++) {
        if (items[i].type.indexOf('image') !== -1) {
          //image
          const file = items[i].getAsFile();
          if (file) {
            this.files.push(file);
          }
        }
      }
    } catch(e) {
      console.error('Failed to extract files from PasteEvent dataTransfer.items' + e);
    }
  }
}
