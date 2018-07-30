import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Injectable} from "@angular/core";

export interface ICKEditorInstance {
  getData():string;
  setData(content:string):void;
  model:any;
  editing:any;
  config:any;
}

export interface ICKEditorStatic {
  create(el:HTMLElement, config?:any):Promise<ICKEditorInstance>;
  createCustomized(el:HTMLElement, config?:any):Promise<ICKEditorInstance>;
}

export interface ICKEditorContext {
  resource?:HalResource;
  // Specific removing of plugins
  removePlugins?:string[];
  // Set of enabled macro plugins or false to disable all
  macros?:false|string[];
  // context link to append on preview requests
  previewContext?:string;
}

declare global {
  interface Window {
    OPConstrainedEditor:ICKEditorStatic;
    OPClassicEditor:ICKEditorStatic;
  }
}

@Injectable()
export class CKEditorSetupService {
 constructor(private PathHelper:PathHelperService) {
 }

  /**
   * Create a CKEditor instance of the given type on the wrapper element.
   * Pass a ICKEditorContext object that will be used to decide active plugins.
   *
   *
   * @param {"full" | "constrained"} type
   * @param {HTMLElement} wrapper
   * @param {ICKEditorContext} context
   * @returns {Promise<ICKEditorInstance>}
   */
 public create(type:'full'|'constrained', wrapper:HTMLElement, context:ICKEditorContext) {
   const editor = type === 'constrained' ? window.OPConstrainedEditor : window.OPClassicEditor;
   wrapper.classList.add(`ckeditor-type-${type}`);

   return editor
     .createCustomized(wrapper, {
       openProject: {
         context: context,
         helpURL: this.PathHelper.textFormattingHelp(),
         pluginContext: window.OpenProject.pluginContext.value
       }
     })
     .then((editor) => {
       // Allow custom events on wrapper to set/get data for debugging
       jQuery(wrapper)
         .on('op:ckeditor:setData', (event:any, data:string) => editor.setData(data))
         .on('op:ckeditor:clear', (event:any) => editor.setData(' '))
         .on('op:ckeditor:getData', (event:any, cb:any) => cb(editor.getData()));

       return editor;
     })
     .catch((error:any) => {
       console.error(`Failed to setup CKEditor instance: ${error}`);
     });
 }
}
