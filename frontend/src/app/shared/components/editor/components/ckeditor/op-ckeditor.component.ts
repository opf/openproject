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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { debounce } from 'lodash-es';
import { ChangeDetectionStrategy, Component, ElementRef, EventEmitter, Input, OnDestroy, OnInit, Output, ViewChild, inject } from '@angular/core';
import type { Editor as CodeMirrorEditor } from 'codemirror';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import {
  ICKEditorContext,
  ICKEditorInstance,
  ICKEditorWatchdog,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import { CKEditorSetupService } from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';
import { CodeMirrorLoaderService } from 'core-app/shared/components/editor/components/ckeditor/codemirror-loader.service';
import { KeyCodes } from 'core-app/shared/helpers/keycodes';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  selector: 'op-ckeditor',
  templateUrl: './op-ckeditor.html',
  styleUrls: ['./op-ckeditor.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class OpCkeditorComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input() context:ICKEditorContext;

  @Input()
  public set content(newVal:string) {
    this._content = newVal || '';

    if (this.initialized) {
      this.ckEditorInstance.setData(this._content);
    }
  }

  // Output notification once ready
  @Output() initializeDone = new EventEmitter<ICKEditorInstance>();

  // Output notification at max once/s for data changes
  @Output() contentChanged = new EventEmitter<string>();

  // Output notification when editor cannot be initialized
  @Output() initializationFailed = new EventEmitter<string>();

  // Output save requests (ctrl+enter and cmd+enter)
  @Output() saveRequested = new EventEmitter<string>();

  @Output() editorEscape = new EventEmitter<string>();

  // Output key up events
  @Output() editorKeyup = new EventEmitter<string>();

  // Output blur events
  @Output() editorBlur = new EventEmitter<string>();

  // Output focus events
  @Output() editorFocus = new EventEmitter<string>();

  // View container of the replacement used to initialize CKEditor5
  @ViewChild('opCkeditorReplacementContainer', { static: true }) opCkeditorReplacementContainer:ElementRef<HTMLDivElement>;

  @ViewChild('codeMirrorPane') codeMirrorPane:ElementRef<HTMLDivElement>;

  // CKEditor instance once initialized
  public watchdog:ICKEditorWatchdog;

  public ckEditorInstance:ICKEditorInstance;

  public error:string|null = null;

  public allowManualMode = false;

  public manualMode = false;

  private _content = '';

  private readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly Notifications = inject(ToastService);
  private readonly I18n = inject(I18nService);
  private readonly configurationService = inject(ConfigurationService);
  private readonly ckEditorSetup = inject(CKEditorSetupService);
  private readonly codeMirrorLoader = inject(CodeMirrorLoaderService);

  public text = {
    errorTitle: this.I18n.t('js.editor.ckeditor_error'),
  };

  // Codemirror instance, initialized lazily when running source mode
  public codeMirrorInstance:CodeMirrorEditor|null = null;

  // Debounce change listener for both CKE and codemirror
  // to read back changes as they happen
  private debouncedEmitter = debounce(
    () => {
      const val = this.getTransformedContent(false);
      this.contentChanged.emit(val);
    },
    1000,
    { leading: true },
  );

  /**
   * Get the current live data from CKEditor. This may raise in cases
   * the data cannot be loaded (MS Edge!)
   */
  public getRawData():string {
    let content:string;

    if (this.manualMode) {
      content = this.codeMirrorInstance!.getValue();
    } else {
      content = this.ckEditorInstance.getData({ trim: false });
    }

    if (content === null || content === undefined) {
      throw new Error('Trying to get content from CKEditor failed, as it returned null.');
    }

    this._content = content;
    return content;
  }

  /**
   * Get a promise with the transformed content, will wrap errors in the promise.
   * @param notificationOnError
   */
  public getTransformedContent(notificationOnError = true):string {
    try {
      if (!this.initialized) {
        throw new Error('Tried to access CKEditor instance before initialization.');
      }

      if (this.componentDestroyed) {
        throw new Error('Component destroyed');
      }

      if (!this.ckEditorInstance || this.ckEditorInstance.state === 'destroyed') {
        console.warn('CKEditor instance is destroyed, returning last content');
        return this._content;
      }

      return this.getRawData();
    } catch (e) {
      if (e instanceof Error) {
        console.error(`Failed to save CKEditor content: ${e.message}.`);

        const error = this.I18n.t(
          'js.editor.error_saving_failed',
          { error: e.message },
        );

        if (notificationOnError) {
          this.Notifications.addError(error);
        }
      }

      return this._content;
    }
  }

  /**
   * Return the current content. This may be outdated a tiny bit.
   */
  public get content() {
    return this._content;
  }

  public get initialized():boolean {
    return this.ckEditorInstance !== undefined;
  }

  ngOnInit() {
    try {
      this.initializeEditor();
    } catch (e) {
      // We will run into this error if, among others, the browser does not fully support
      // CKEditor's requirements on ES6.
      console.error('Failed to setup CKEditor instance: %O', e);
      if (e instanceof Error) {
        this.error = e.message;
        this.initializationFailed.emit(e.message);
      }
    }
  }

  ngOnDestroy() {
    try {
      this.watchdog?.destroy();
    } catch (e) {
      console.error('Failed to destroy CKEditor instance:', e);
    }
  }

  private initializeEditor() {
    void this.ckEditorSetup
      .create(
        this.opCkeditorReplacementContainer.nativeElement,
        this.context,
        this.content,
      )
      .catch((error:string) => {
        throw (error);
      })
      .then((watchdog:ICKEditorWatchdog) => {
        this.setupWatchdog(watchdog);
        const editor = watchdog.editor;
        this.ckEditorInstance = editor;

        // Switch mode
        editor.on('op:source-code-enabled', () => this.enableManualMode());
        editor.on('op:source-code-disabled', () => this.disableManualMode());

        // Capture CTRL+ENTER commands
        this.interceptModifiedEnterKeystrokes(editor);

        // Capture and emit key up events
        this.interceptKeyup(editor);

        // Capture and emit blur events
        this.interceptBlur(editor);

        // Emit global dragend events for other drop zones to react.
        // This is needed, as CKEditor does not bubble any drag events
        const model = watchdog.editor.model;
        model.document.on('change', this.debouncedEmitter);
        model.on('op:attachment-added', () => document.body.dispatchEvent(new DragEvent('dragend')));
        model.on('op:attachment-removed', () => document.body.dispatchEvent(new DragEvent('dragend')));

        this.initializeDone.emit(watchdog.editor);
        return watchdog.editor;
      });
  }

  private interceptModifiedEnterKeystrokes(editor:ICKEditorInstance) {
    editor.listenTo(
      editor.editing.view.document,
      'keydown',
      (evt, data) => {
        if ((data.ctrlKey || data.metaKey) && data.keyCode === KeyCodes.ENTER) {
          debugLog('Sending save request from CKEditor.');
          this.saveRequested.emit();
          evt.stop();
        }

        if (data.keyCode === KeyCodes.ESCAPE) {
          this.editorEscape.emit();
          evt.stop();
        }
      },
      { priority: 'highest' },
    );
  }

  private interceptKeyup(editor:ICKEditorInstance) {
    editor.listenTo(
      editor.editing.view.document,
      'keyup',
      (event) => {
        this.editorKeyup.emit();
        event.stop();
      },
      { priority: 'highest' },
    );
  }

  private interceptBlur(editor:ICKEditorInstance) {
    editor.listenTo(
      editor.editing.view.document,
      'change:isFocused',
      () => {
        // without the timeout `isFocused` is still true even if the editor was blurred
        // current limitation:
        // clicking on empty toolbar space and the somewhere else on the page does not trigger the blur anymore
        setTimeout(() => {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
          if (!editor.ui.focusTracker.isFocused) {
            this.editorBlur.emit();
          } else {
            this.editorFocus.emit();
          }
        }, 0);
      },
      { priority: 'highest' },
    );
  }

  /**
   * Disable the manual mode, kill the codeMirror instance and switch back to CKEditor
   */
  private disableManualMode() {
    const current = this.getRawData();

    // Apply content to ckeditor
    this.ckEditorInstance.setData(current);
    this.codeMirrorInstance = null;
    this.manualMode = false;
  }

  /**
   * Enable manual mode, get data from WYSIWYG and show CodeMirror instance.
   */
  private enableManualMode() {
    const current = this.getRawData();
    const cmMode = 'gfm';

    void this.codeMirrorLoader
      .ensureModeLoaded(cmMode)
      .then((modeLoaded) => modeLoaded ? cmMode : '')
      .then(async (resolvedMode) => {
        const CodeMirror = await this.codeMirrorLoader.loadCore();
        this.codeMirrorInstance = CodeMirror(
          this.elementRef.nativeElement.querySelector<HTMLElement>('.ck-editor__source')!,
          {
            lineNumbers: true,
            smartIndent: true,
            value: current,
            mode: resolvedMode,
          },
        );

        this.codeMirrorInstance.on('change', this.debouncedEmitter);
        setTimeout(() => this.codeMirrorInstance!.refresh(), 100);
        this.manualMode = true;
      });
  }

  /**
   * Listen to some of the error events of the watchdog to provide the
   * user with some information on what went wrong.
   *
   * @param watchdog
   * @private
   */
  private setupWatchdog(watchdog:ICKEditorWatchdog) {
    this.watchdog = watchdog;

    watchdog.on('error', (_, { error }) => {
      this.error = error.message;
    });
  }
}
