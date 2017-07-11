import IAugmentedJQuery = angular.IAugmentedJQuery;
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class PasteModel {
  public files:File[];

  constructor(protected dataTransfer:DataTransfer) {

    this.files = this.extractFiles();
  }

  private extractFiles():File[] {
    const files:File[] = [];
    const items = this.dataTransfer.items;
    if (!items) {
      return files;
    }

    for (let i = 0; i < items.length; i++) {
      if (items[i].type.indexOf("image") !== -1) {
        //image
        const blob = items[i].getAsFile()!;
        files.push(blob);
      }
    }

    return files;
  }
}
