//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { escapeRegExp } from 'lodash-es';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { Injectable, inject } from '@angular/core';
import {
  ICKEditorContext,
  ICKEditorStatic,
  ICKEditorWatchdog,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import { Constructor } from '@angular/cdk/schematics';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

export type ICKEditorType = 'full'|'constrained';

// What editor authors pass; resolveMacros() turns it into an ICKEditorResolvedMacros value.
// The wiki-link macros are appended to any array result when a wiki provider is available.
//   'none' / false → no macros (dropdown hidden)
//   'resource'     → ToC, embedded table, WP button/quickinfo (+ wiki links when available)
//   'wiki'         → only the wiki links, and only when a provider is available (else none)
//   true           → keep every macro the build ships, regardless of wiki availability
//   string[]       → exactly these macro plugin names (+ wiki links when available)
export type ICKEditorMacroType = 'none'|'resource'|'wiki'|boolean|string[];

// What the CKEditor build consumes: false = none, true = all, array = exactly these.
export type ICKEditorResolvedMacros = boolean|string[];

// Wiki-page-link macros, added to any editor when a wiki provider is configured (see resolveMacros).
const wikiLinkMacros = ['OpMacroWikiPageLinkAddExisting', 'OpMacroWikiPageLinkCreateNew'];

declare global {
  interface Window {
    OPConstrainedEditor:ICKEditorStatic;
    OPClassicEditor:ICKEditorStatic;
    OPEditorWatchdog:Constructor<ICKEditorWatchdog>;
  }
}

@Injectable()
export class CKEditorSetupService {
  readonly PathHelper = inject(PathHelperService);
  readonly configurationService = inject(ConfigurationService);

  /** The language CKEditor was able to load, falls back to 'en' */
  private loadedLocale = 'en';

  /** Prefetch ckeditor when browser is idle */
  private prefetch:Promise<unknown>;

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

    const toolbarWrapper = wrapper.querySelector<HTMLElement>('.document-editor__toolbar');
    const contentWrapper = wrapper.querySelector<HTMLElement>('.document-editor__editable');
    if (!toolbarWrapper || !contentWrapper) {
      throw new Error('Missing CKEditor wrapper elements.');
    }
    const config = this.createConfig(context, initialData);

    return this
      .createWatchdog(editorClass, contentWrapper, config)
      .then((watchdog:ICKEditorWatchdog) => {
        const { editor } = watchdog;
        const updateLastUpdated = () => {
          const editable = wrapper.querySelector<HTMLElement>('.ck-editor__editable_inline');
          if (!editable) {
            return;
          }

          editable.dataset.lastUpdated = String(new Date().getTime());
        };
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        toolbarWrapper.appendChild(editor.ui.view.toolbar.element);

        // Allow custom events on wrapper to set/get data for debugging
        wrapper.addEventListener('op:ckeditor:autosave', () => {
          editor.config.get('autosave').save(editor);
        });
        wrapper.addEventListener('op:ckeditor:setData', (event:CustomEvent<string>) => {
          editor.setData(event.detail);
          updateLastUpdated();
        });
        wrapper.addEventListener('op:ckeditor:clear', () => {
          editor.setData(' ');
          updateLastUpdated();
        });
        wrapper.addEventListener('op:ckeditor:getData', (event:CustomEvent<(data:string) => void>) => {
          event.detail(editor.getData({ trim: false }));
        });

        return watchdog;
      });
  }

  private createConfig(context:ICKEditorContext, initialData:string|null) {
    const uiLocale = this.loadedLocale;
    const contentLanguage = context.options?.rtl ? 'ar' : 'en';
    const resolvedContext:ICKEditorContext = { ...context, macros: this.resolveMacros(context.macros) };

    const config = {
      openProject: this.createContext(resolvedContext),
      removePlugins: context.removePlugins,
      initialData,
      ui: {
        poweredBy: {
          side: 'left',
        },
      },
      language: {
        ui: uiLocale,
        content: contentLanguage,
      },
      link: {},
      storageKey: context.storageKey,
      // Constrained editors have no macro dropdown by default; add one when macros are present.
      ...(context.type === 'constrained' && Array.isArray(resolvedContext.macros)
        ? { toolbar: { items: this.constrainedToolbarWithMacroList() } }
        : {}),
    };

    const allowedLinkProtocols = this.configurationService.allowedLinkProtocols;
    if (allowedLinkProtocols) {
      config.link = { allowedProtocols: allowedLinkProtocols.map((el:string) => escapeRegExp(el)) };
    }

    return config;
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
    // untyped modules cannot be dynamically imported
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const loadEditorScript = import('core-vendor/ckeditor/ckeditor');

    const promises = [loadEditorScript];

    if (I18n.locale !== 'en') {
      promises.push(this.loadLocale());
    }

    await Promise.all(promises);
  }

  private async loadLocale():Promise<void> {
    try {
      await import(`../../../../../../vendor/ckeditor/translations/${I18n.locale}.js`);
      this.loadedLocale = I18n.locale;
    } catch (e:unknown) {
      console.warn(`Failed to load translation for CKEditor: ${e as string}`);
    }
  }

  private createContext(context:ICKEditorContext):unknown {
    return {
      context,
      helpURL: this.PathHelper.textFormattingHelp(),
      pluginContext: window.OpenProject.pluginContext.value,
    };
  }

  // Splice `macroList` into the constrained editor's own toolbar (which omits it by default).
  private constrainedToolbarWithMacroList():string[] {
    const items = [...(window.OPConstrainedEditor.defaultConfig?.toolbar?.items ?? [])];

    if (!items.includes('macroList')) {
      const anchor = items.indexOf('blockQuote');
      const insertAt = anchor === -1 ? items.length : anchor + 1;
      items.splice(insertAt, 0, '|', 'macroList');
    }

    return items;
  }

  // Expand macro tokens and add/withhold the wiki macros based on `wikisAvailable`.
  // `false`/`'none'` stay macro-free, keeping custom fields and read-only editors untouched.
  private resolveMacros(macros:ICKEditorMacroType|undefined):ICKEditorResolvedMacros {
    let resolved = macros;

    if (!resolved || resolved === 'none') {
      return false;
    }
    if (resolved === true) {
      return true;
    }
    if (resolved === 'resource') {
      resolved = [
        'OPMacroToc',
        'OPMacroEmbeddedTable',
        'OPMacroWpButton',
        'OPMacroWpQuickinfo',
      ];
    } else if (resolved === 'wiki') {
      resolved = [];
    }

    if (Array.isArray(resolved)) {
      resolved = this.configurationService.wikisAvailable
        ? [...new Set([...resolved, ...wikiLinkMacros])]
        : resolved.filter((name) => !wikiLinkMacros.includes(name));

      // Empty set ⇒ false, so no (empty) dropdown is shown.
      if (resolved.length === 0) {
        return false;
      }
    }

    return resolved;
  }

  private watchTopLayer() {
    const floatingUi = () => document.querySelectorAll<HTMLElement>('.ck-body-wrapper, [class*="ck-inspector-"]');

    // querySelectorAll preserves document order
    const frontMostOpenDialog = ():HTMLElement|null => {
      const open = document.querySelectorAll<HTMLDialogElement>('dialog[open]');
      return open.length ? open[open.length - 1] : null;
    };

    // wrapper lives inside the modal while one is open and returns to document.body afterwards
    const place = () => {
      const target = frontMostOpenDialog() ?? document.body;
      floatingUi().forEach((node) => {
        if (node.parentElement !== target) {
          target.appendChild(node);
        }
      });
    };

    // wrapper and <dialog-helper> are child of document.body
    const isRelevantChild = (nodes:NodeList):boolean => Array.from(nodes).some((node) => (
      node instanceof HTMLElement
      && node.matches('.ck-body-wrapper, [class*="ck-inspector-"], dialog, dialog-helper')
    ));
    const childObserver = new MutationObserver((mutations) => {
      if (mutations.some((mutation) => isRelevantChild(mutation.addedNodes) || isRelevantChild(mutation.removedNodes))) {
        place();
      }
    });
    childObserver.observe(document.body, { childList: true });

    // `open` attribute toggled by dialog opening/closing
    const openAttrObserver = new MutationObserver(place);
    openAttrObserver.observe(document.body, { attributes: true, attributeFilter: ['open'], subtree: true });

    place();
  }
}
