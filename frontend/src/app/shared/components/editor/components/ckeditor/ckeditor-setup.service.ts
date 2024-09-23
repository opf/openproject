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
  /** The language CKEditor was able to load, falls back to 'en' */
  private loadedLocale = 'en';

  /** Prefetch ckeditor when browser is idle */
  private prefetch:Promise<unknown>;

  constructor(private PathHelper:PathHelperService) {
  }

  public initialize() {
    this.prefetch = this.load();
    this.watchTopLayer();
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
    wrapper:HTMLElement,
    context:ICKEditorContext,
    initialData:string|null = null,
  ):Promise<ICKEditorWatchdog> {
    // Load the bundle and the matching locale, if found.
    await this.prefetch;

    const { type } = context;
    const editorClass = type === 'constrained' ? window.OPConstrainedEditor : window.OPClassicEditor;
    wrapper.classList.add(`ckeditor-type-${type}`);

    const toolbarWrapper = wrapper.querySelector('.document-editor__toolbar') as HTMLElement;
    const contentWrapper = wrapper.querySelector('.document-editor__editable') as HTMLElement;
    const uiLocale = this.loadedLocale;
    const contentLanguage = context.options && context.options.rtl ? 'ar' : 'en';

    const config = {
      openProject: this.createConfig(context),
      removePlugins: context.removePlugins,
      initialData,
      language: {
        ui: uiLocale,
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
          // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-return
          .on('op:ckeditor:autosave', () => editor.config.get('autosave').save(editor))
          .on('op:ckeditor:setData', (_, data:string) => editor.setData(data))
          .on('op:ckeditor:clear', () => editor.setData(' '))
          .on('op:ckeditor:getData', (_, cb:(data:string) => void) => cb(editor.getData({ trim: false })));

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
  private async load():Promise<void> {
    // untyped module cannot be dynamically imported
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    await import(/* webpackPrefetch: true; webpackChunkName: "ckeditor" */ 'core-vendor/ckeditor/ckeditor');

    try {
      await import(
        /* webpackPrefetch: true; webpackChunkName: "ckeditor-translation" */ `../../../../../../vendor/ckeditor/translations/${I18n.locale}.js`
      ) as unknown;
      this.loadedLocale = I18n.locale;
    } catch (e:unknown) {
      console.warn(`Failed to load translation for CKEditor: ${e as string}`);
    }
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

  private watchTopLayer() {
    const targetClassNames = ['ck-body-wrapper', 'ck-inspector-'];

    const observer = new MutationObserver((mutations) => {
      const dialog = document.querySelector('dialog[open]');
      if (!dialog) {
        return;
      }

      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (!(node instanceof HTMLElement)) {
            return;
          }

          if (targetClassNames.some((className) => node.classList.contains(className))) {
            dialog.append(node);
          }
        });
      });
    });

    observer.observe(document.body, {
      childList: true,
    });
  }
}
