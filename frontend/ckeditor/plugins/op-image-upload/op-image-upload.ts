const Plugin:any = (require('@ckeditor/ckeditor5-core/src/plugin') as any).default;
const Image:any = (require('@ckeditor/ckeditor5-image/src/image') as any).default;
const FileRepository:any = (require('@ckeditor/ckeditor5-upload/src/filerepository') as any).default;
const ImageUpload:any = (require('@ckeditor/ckeditor5-upload/src/imageupload') as any).default;
const ImageUploadEngine:any = (require('@ckeditor/ckeditor5-upload/src/imageuploadengine') as any).default;

import { OpenProjectUploadAdapter } from './op-upload-adadpter';

interface CkEditorInstance {
  plugins:any;
}

interface IFileLoader {
  file:File;
  uploadTotal?:number;
  uploaded?:number;
}

export default class OPImageUploadPlugin extends Plugin {
  public editor:CkEditorInstance;

	static get requires() {
		return [
			Image,
      ImageUpload,
      ImageUploadEngine,
      FileRepository
		];
  }

  init() {
    this.editor.plugins.get( FileRepository ).createAdapter = (loader:IFileLoader) => {
      return new OpenProjectUploadAdapter(loader as any, this.editor);
		};
  }

	static get pluginName() {
		return 'OpenProject Image Upload';
	}
}
