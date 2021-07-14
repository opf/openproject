import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { Injectable } from '@angular/core';
import {
  ICKEditorContext,
  ICKEditorStatic,
  ICKEditorWatchdog,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import { Constructor } from '@angular/cdk/schematics';

export type ICKEditorType = 'full'|'constrained';
export type ICKEditorMacroType = 'none'|'resource'|'full'|boolean|string[];

declare global {
  interface Window {
    OPConstrainedEditor:ICKEditorStatic;
    OPClassicEditor:ICKEditorStatic;
    OPEditorWatchdog:Constructor<ICKEditorWatchdog>;
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
   * Returns a Watchdog instance that has access to the editor and monitors its state.
   *
   * @param {HTMLElement} wrapper
   * @param {ICKEditorContext} context
   * @param {string|null} initialData
   * @returns {Promise<ICKEditorWatchdog>}
   */
  public async create(
    wrapper:HTMLElement, context:ICKEditorContext,
    initialData:string|null = null,
  ):Promise<ICKEditorWatchdog> {
    // Load the bundle
    await CKEditorSetupService.load();

    const { type } = context;
    const editorClass = type === 'constrained' ? window.OPConstrainedEditor : window.OPClassicEditor;
    wrapper.classList.add(`ckeditor-type-${type}`);

    const toolbarWrapper = wrapper.querySelector('.document-editor__toolbar') as HTMLElement;
    const contentWrapper = wrapper.querySelector('.document-editor__editable') as HTMLElement;
    const contentLanguage = context.options && context.options.rtl ? 'ar' : 'en';

    const config = {
      openProject: this.createConfig(context),
      initialData,
      language: {
        content: contentLanguage,
      },
    };

    return this
      .createWatchdog(editorClass, contentWrapper, config)
      .then((watchdog:ICKEditorWatchdog) => {
        const { editor } = watchdog;
        toolbarWrapper.appendChild(editor.ui.view.toolbar.element);

        // Allow custom events on wrapper to set/get data for debugging
        jQuery(wrapper)
          .on('op:ckeditor:setData', (event:unknown, data:string) => editor.setData(data))
          .on('op:ckeditor:clear', () => editor.setData(' '))
          .on('op:ckeditor:getData', (event:unknown, cb:(data:string) => void) => cb(editor.getData({ trim: false })));

        return watchdog;
      });
  }

  /**
   * Build the given editor class with a watchdog around it, returning the watchdog.
   *
   * @param editorClass
   * @param contentWrapper
   * @param config
   * @private
   */
  private createWatchdog(
    editorClass:ICKEditorStatic,
    contentWrapper:HTMLElement,
    config:unknown,
  ):Promise<ICKEditorWatchdog> {
    const watchdog = new window.OPEditorWatchdog();

    watchdog.setCreator(() => editorClass.createCustomized(contentWrapper, config));
    watchdog.setDestructor((editor) => editor.destroy());

    return watchdog
      .create(contentWrapper, {})
      .then(() => watchdog);
  }

  /**
   * Load the ckeditor asset
   */
  private static load():Promise<unknown> {
    // untyped module cannot be dynamically imported
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    return import(/* webpackChunkName: "ckeditor" */ 'core-vendor/ckeditor/ckeditor.js');
  }

  private createConfig(context:ICKEditorContext):unknown {
    if (context.macros === 'none') {
      context.macros = false;
    } else if (context.macros === 'resource') {
      context.macros = [
        'OPMacroToc',
        'OPMacroEmbeddedTable',
        'OPMacroWpButton',
      ];
    }

    return {
      context,
      helpURL: this.PathHelper.textFormattingHelp(),
      pluginContext: window.OpenProject.pluginContext.value,
    };
  }
}
