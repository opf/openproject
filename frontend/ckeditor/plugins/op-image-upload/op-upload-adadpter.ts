
import IFileLoader from './op-image-upload';
import {$injectFields} from 'core-components/angular/angular-injector-bridge.functions';

export class OpenProjectUploadAdapter {
  // Injected service
  public Upload:any;

  // Upload instance
  public uploader:any;

  constructor(public loader:IFileLoader, public editor:any) {
    // Save Loader instance to update upload progress.
    this.loader = loader;
    // $injectFields(this, 'Upload');
  }

  public get uploadUrl() {
    const config = this.editor.config.openProject;
    return config.context.addAttachment.href;
  }

  public upload() {
    const file = this.loader.file;
    const metadata = {
      description: file.description,
      fileName: file.customName || file.name
    };

    // need to wrap the metadata into a JSON ourselves as ngFileUpload
    // will otherwise break up the metadata into individual parts
    const data =  {
      metadata: JSON.stringify(metadata),
      file: this.loader.file
    };

    return this.uploader = this.performUpload(data, this.uploadUrl);
  }

  public performUpload(data:any, url:string) {
    const uploader = this.Upload.upload({data, url});
    uploader.progress((details:any) => {
      var file = details.config.file || details.config.data.file;
      if (details.lengthComputable) {
        this.loader.uploaded = details.loaded;
        this.loader.uploadTotal = details.total;
      }
    });

    // Return srcset data for image
    // https://ckeditor5.github.io/docs/nightly/ckeditor5/latest/api/module_upload_filerepository-Adapter.html#upload
    return uploader.then((result:any) => {
      return { default: result.data._links.downloadLocation.href };
    });
  }

  abort() {
    return this.uploader && this.uploader.abort();
  }

}
