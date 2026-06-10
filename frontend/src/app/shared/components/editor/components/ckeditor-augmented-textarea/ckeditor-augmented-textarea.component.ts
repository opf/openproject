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

import { ChangeDetectionStrategy, Component, ElementRef, EventEmitter, Input, OnInit, Output, ViewChild, inject } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { States } from 'core-app/core/states/states.service';
import { filter, takeUntil } from 'rxjs/operators';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ICKEditorMacroType,
  ICKEditorType,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';
import { OpCkeditorComponent } from 'core-app/shared/components/editor/components/ckeditor/op-ckeditor.component';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  ICKEditorContext,
  ICKEditorInstance,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import { fromEvent, Subscription } from 'rxjs';
import { AttachmentCollectionResource } from 'core-app/features/hal/resources/attachment-collection-resource';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { navigator } from '@hotwired/turbo';
import { attributeTokenList, ensureId } from 'core-app/shared/helpers/dom-helpers';

@Component({
  templateUrl: './ckeditor-augmented-textarea.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class CkeditorAugmentedTextareaComponent extends UntilDestroyedMixin implements OnInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  protected pathHelper = inject(PathHelperService);
  protected halResourceService = inject(HalResourceService);
  protected Notifications = inject(ToastService);
  protected I18n = inject(I18nService);
  protected states = inject(States);

  // Track form submission "in-flight" state per form, to prevent multiple
  // submissions from multiple CKEditor instances on the same form.
  private static inFlight = new WeakMap<HTMLFormElement, boolean>();

  @Input() public textAreaId:string;

  @Input() public previewContext:string;

  @Input() public macros:ICKEditorMacroType;

  @Input() public removePlugins:string[] = [];

  @Input() public resource?:object;

  @Input() public turboMode = false;

  @Input() public editorType:ICKEditorType = 'full';

  @Input() public showAttachments = true;

  @Input() public primerized = false;

  @Input() public storageKey?:string;

  // Output save requests (ctrl+enter and cmd+enter)
  @Output() saveRequested = new EventEmitter<string>();

  @Output() editorEscape = new EventEmitter<string>();

  // Output keyup events
  @Output() editorKeyup = new EventEmitter<void>();

  // Output blur events
  @Output() editorBlur = new EventEmitter<void>();

  // Output focus events
  @Output() editorFocus = new EventEmitter<void>();

  // Which template to include
  public element:HTMLElement;

  public formElement:HTMLFormElement;

  public wrappedTextArea:HTMLTextAreaElement;

  // Remember if the user changed
  public changed = false;

  public initialContent:string;

  public readOnly = false;

  public halResource?:HalResource&{ attachments:AttachmentCollectionResource };

  public context:ICKEditorContext;

  public text = {
    attachments: this.I18n.t('js.label_attachments'),
  };

  private focused = false;

  // Reference to the actual ckeditor instance component
  @ViewChild(OpCkeditorComponent, { static: true }) private ckEditorInstance:OpCkeditorComponent;

  private attachments:HalResource[];

  private labelClickSubscription:Subscription;

  constructor() {
    super();
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    this.element = this.elementRef.nativeElement;

    // Parse the resource if any exists
    this.halResource = this.resource ? this.halResourceService.createHalResource(this.resource, true) : undefined;

    this.formElement = this.element.closest('form')!;

    this.wrappedTextArea = document.getElementById(this.textAreaId) as HTMLTextAreaElement;

    this.wrappedTextArea.style.display = 'none';
    this.wrappedTextArea.required = false;
    this.initialContent = this.wrappedTextArea.value;
    this.readOnly = this.wrappedTextArea.disabled;

    this.context = {
      type: this.editorType,
      resource: this.halResource,
      field: this.wrappedTextArea.name,
      previewContext: this.previewContext,
      removePlugins: this.removePlugins,
      storageKey: this.storageKey,
    };
    if (this.readOnly) {
      this.context.macros = 'none';
    } else if (this.macros) {
      this.context.macros = this.macros;
    }

    this.registerFormSubmitListener();
  }

  private registerFormSubmitListener():void {
    fromEvent(this.formElement, 'submit')
      .pipe(
        filter(() => !CkeditorAugmentedTextareaComponent.inFlight.has(this.formElement)),
        this.untilDestroyed(),
      )
      .subscribe((evt:SubmitEvent) => {
        evt.preventDefault();
        void this.saveForm(evt);
      });
  }

  public editorFocused():void {
    this.focused = true;
    this.editorFocus.emit();
  }

  public editorBlurred():void {
    this.focused = false;
    this.editorBlur.emit();
  }

  public async saveForm(evt?:SubmitEvent):Promise<void> {
    if (CkeditorAugmentedTextareaComponent.inFlight.has(this.formElement)) {
      return;
    }

    CkeditorAugmentedTextareaComponent.inFlight.set(this.formElement, true);

    this.syncToTextarea();
    window.OpenProject.pageState = 'submitted';

    setTimeout(() => {
      if (evt?.submitter) {
        (evt.submitter as HTMLInputElement).disabled = false;
      }

      if (this.turboMode && !this.formElement.dataset.action) {
        navigator.submitForm(this.formElement, evt?.submitter ?? undefined);
      } else {
        this.formElement.requestSubmit(evt?.submitter);
      }

      CkeditorAugmentedTextareaComponent.inFlight.delete(this.formElement);
    });
  }

  private constrainGroupedDropdownToEditorWidth(_editor:ICKEditorInstance) {
    const host = this.elementRef.nativeElement;

    const editorWidth = () => {
      const editorEl = host.querySelector<HTMLElement>('.ck-editor') ?? host;
      return Math.floor(editorEl.getBoundingClientRect().width);
    };

    const apply = () => {
      const width = editorWidth();

      const panels = Array.from(
        document.querySelectorAll<HTMLElement>(
          '.ck.ck-dropdown__panel'
        )
      );

      for (const panel of panels) {
        panel.style.maxWidth = `${width - 8}px`;

      }
    };

    fromEvent(host, 'click')
      .pipe(this.untilDestroyed())
      .subscribe(() => setTimeout(apply));
  }

  public setup(editor:ICKEditorInstance) {
    this.setupMarkingReadonlyWhenTextareaIsDisabled(editor);

    if (this.halResource?.attachments) {
      this.setupAttachmentAddedCallback(editor);
      this.setupAttachmentRemovalSignal(editor);
    }

    // Set initial label
    this.setLabel();

    // Use focusTracker to maintain aria-labelledby as CKEditor re-renders aria-label on every focus/blur event
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-member-access
    editor.ui.focusTracker.on('change:isFocused', (_evt:unknown, _name:string, _isFocused:boolean) => {
      this.setLabel();
    });
    this.constrainGroupedDropdownToEditorWidth(editor);

    return editor;
  }

  public updateContent(value:string) {
    // Update the page state to edited
    // but only if we're focused in the editor
    if (this.focused) {
      window.OpenProject.pageState = 'edited';
    }

    this.wrappedTextArea.value = value;
  }

  public syncToTextarea() {
    try {
      this.wrappedTextArea.value = this.ckEditorInstance.getTransformedContent(true);
    } catch (e) {
      // eslint-disable-next-line @typescript-eslint/no-base-to-string
      const message = (e as Error)?.message || (e as object).toString();
      console.error(`Failed to save CKEditor body to textarea: ${message}.`);
      this.Notifications.addError(message || this.I18n.t('js.error.internal'));
      throw e;
    }
  }

  private setupAttachmentAddedCallback(editor:ICKEditorInstance) {
    editor.model.on('op:attachment-added', () => {
      this.states.forResource(this.halResource as HalResource)?.putValue(this.halResource);
    });
  }

  private setupAttachmentRemovalSignal(editor:ICKEditorInstance) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-unsafe-member-access
    this.attachments = _.clone((this.halResource as HalResource).attachments.elements);

    this
      .states
      .forResource(this.halResource as HalResource)
      ?.changes$()
      .pipe(
        takeUntil(componentDestroyed(this)),
        filter((resource) => !!resource),
      )
      .subscribe((resource:HalResource&{ attachments:AttachmentCollectionResource }) => {
        const missingAttachments = _.differenceBy(
          this.attachments,
          resource.attachments.elements,
          (attachment:HalResource) => attachment.id,
        );

        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-return
        const removedUrls = missingAttachments.map((attachment) => attachment.downloadLocation.href);

        if (removedUrls.length) {
          editor.model.fire('op:attachment-removed', removedUrls);
        }

        this.attachments = _.clone(resource.attachments.elements);
      });
  }

  private setupMarkingReadonlyWhenTextareaIsDisabled(editor:ICKEditorInstance) {
    const observer = new MutationObserver((_mutations) => {
      if (this.readOnly !== this.wrappedTextArea.disabled) {
        this.readOnly = this.wrappedTextArea.disabled;
        if (this.readOnly) {
          editor.enableReadOnlyMode('wrapped-text-area-disabled');
        } else {
          editor.disableReadOnlyMode('wrapped-text-area-disabled');
        }
      }
    });
    observer.observe(this.wrappedTextArea, { attributes: true });

    if (this.readOnly) {
      editor.enableReadOnlyMode('wrapped-text-area-disabled');
    }
  }

  private setLabel() {
    const label = document.querySelector<HTMLLabelElement>(`label[for=${this.textAreaId}]`);
    if (!label) {
      console.error(`Please provide a label for the textarea with id ${this.textAreaId}`);
      return;
    }

    const ckContent = this.element.querySelector<HTMLElement>('.ck-content')!;

    ckContent.removeAttribute('aria-label');
    attributeTokenList(ckContent, 'aria-labelledby').add(ensureId(label, 'label'));

    if (!this.labelClickSubscription) {
      this.labelClickSubscription = fromEvent(label, 'click')
        .pipe(this.untilDestroyed())
        .subscribe(() => ckContent.focus());
    }
  }
}
