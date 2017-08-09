import {UploadFile} from '../../../api/op-file-upload/op-file-upload.service';

export class PasteModel {
  public files:UploadFile[] = [];

  constructor(protected dataTransfer:DataTransfer) {
    this.extractFiles(dataTransfer.files);

    // Try to extract files from dataTransfer.items
    // to support older versions of Chrome.
    if (this.files.length === 0) {
      this.extractItems(dataTransfer.items);
    }

    for (let i = 0; i < this.files.length; i++) {
      const file = this.files[i];
      const date = Date.now().toString();
      const extension = file.type.split('/')[1];
      const newName = `${date}-${i}.${extension}`;

      if (!file.name || file.name.indexOf('image.') === 0) {
        file.customName = newName;
      }
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
