import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { Injectable } from "@angular/core";

export interface ICKEditorInstance {
  getData(obtions:{ trim:boolean }):string;

  setData(content:string):void;

  on(event:string, callback:Function):void;

  model:any;
  editing:any;
  config:any;
  ui:any;
  element:HTMLElement;
}

export interface ICKEditorStatic {
  create(el:HTMLElement, config?:any):Promise<ICKEditorInstance>;

  createCustomized(el:string|HTMLElement, config?:any):Promise<ICKEditorInstance>;
}

export interface ICKEditorContext {
  resource?:HalResource;
  // Specific removing of plugins
  removePlugins?:string[];
  // Set of enabled macro plugins or false to disable all
  macros?:'none'|'wp'|'full'|boolean|string[];
  // Additional options like the text orientation of the editors content
  options?:{
    rtl?:boolean;
  };
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
  public async create(type:'full'|'constrained', wrapper:HTMLElement, context:ICKEditorContext, initialData:string|null = null) {
    // Load the bundle
    await this.load();

    const editorClass = type === 'constrained' ? window.OPConstrainedEditor : window.OPClassicEditor;
    wrapper.classList.add(`ckeditor-type-${type}`);

    const toolbarWrapper = wrapper.querySelector('.document-editor__toolbar') as HTMLElement;
    const contentWrapper = wrapper.querySelector('.document-editor__editable') as HTMLElement;

    var contentLanguage = context.options && context.options.rtl ? 'ar' : 'en';


    const editor:ICKEditorInstance = await editorClass
      .createCustomized(contentWrapper, {
        openProject: this.createConfig(context),
        initialData: initialData,
        language: {
          content: contentLanguage
        }
      });

    toolbarWrapper.appendChild(editor.ui.view.toolbar.element);

    // Allow custom events on wrapper to set/get data for debugging
    jQuery(wrapper)
      .on('op:ckeditor:setData', (event:any, data:string) => editor.setData(data))
      .on('op:ckeditor:clear', (event:any) => editor.setData(' '))
      .on('op:ckeditor:getData', (event:any, cb:any) => cb(editor.getData({ trim: false })));

    return editor;
  }

  /**
   * Load the ckeditor asset
   */
  private load():Promise<unknown> {
    // untyped module cannot be dynamically imported
    // @ts-ignore
    return import(/* webpackChunkName: "ckeditor" */ 'core-vendor/ckeditor/ckeditor.js');
  }

  private createConfig(context:ICKEditorContext):any {
    if (context.macros === 'none') {
      context.macros = false;
    } else if (context.macros === 'wp') {
      context.macros = [
        'OPMacroToc',
        'OPMacroEmbeddedTable',
        'OPMacroWpButton'
      ];
    } else {
      context.macros = context.macros;
    }

    return {
      context: context,
      helpURL: this.PathHelper.textFormattingHelp(),
      pluginContext: window.OpenProject.pluginContext.value
    };
  }
}
