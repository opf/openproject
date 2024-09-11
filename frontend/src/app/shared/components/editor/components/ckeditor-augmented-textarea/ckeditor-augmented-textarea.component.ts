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

import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit, ViewChild } from '@angular/core';
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
import { fromEvent } from 'rxjs';
import { AttachmentCollectionResource } from 'core-app/features/hal/resources/attachment-collection-resource';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { navigator } from '@hotwired/turbo';


@Component({
  templateUrl: './ckeditor-augmented-textarea.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CkeditorAugmentedTextareaComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public textareaSelector:string;

  @Input() public previewContext:string;

  @Input() public macros:ICKEditorMacroType;

  @Input() public removePlugins:string[] = [];

  @Input() public resource?:object;

  @Input() public turboMode = false;

  @Input() public editorType:ICKEditorType = 'full';

  @Input() public showAttachments = true;

  // Which template to include
  public element:HTMLElement;

  public formElement:HTMLFormElement;

  public wrappedTextArea:HTMLTextAreaElement;

  // Remember if the user changed
  public changed = false;

  public inFlight = false;

  public initialContent:string;

  public readOnly = false;

  public halResource?:HalResource&{ attachments:AttachmentCollectionResource };

  public context:ICKEditorContext;

  public text = {
    attachments: this.I18n.t('js.label_attachments'),
  };

  // Reference to the actual ckeditor instance component
  @ViewChild(OpCkeditorComponent, { static: true }) private ckEditorInstance:OpCkeditorComponent;

  private attachments:HalResource[];

  constructor(
    readonly elementRef:ElementRef<HTMLElement>,
    protected pathHelper:PathHelperService,
    protected halResourceService:HalResourceService,
    protected Notifications:ToastService,
    protected I18n:I18nService,
    protected states:States,
  ) {
    super();
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    this.element = this.elementRef.nativeElement;

    // Parse the resource if any exists
    this.halResource = this.resource ? this.halResourceService.createHalResource(this.resource, true) : undefined;

    this.formElement = this.element.closest<HTMLFormElement>('form') as HTMLFormElement;
    this.wrappedTextArea = this.formElement.querySelector(this.textareaSelector) as HTMLTextAreaElement;
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
        filter(() => !this.inFlight),
        this.untilDestroyed(),
      )
      .subscribe((evt:SubmitEvent) => {
        evt.preventDefault();
        void this.saveForm(evt);
      });
  }

  public markEdited() {
    window.OpenProject.pageWasEdited = true;
  }

  public async saveForm(evt?:SubmitEvent):Promise<void> {
    this.inFlight = true;

    this.syncToTextarea();
    window.OpenProject.pageIsSubmitted = true;

    setTimeout(() => {
      if (evt?.submitter) {
        (evt.submitter as HTMLInputElement).disabled = false;
      }

      if (this.turboMode) {
        navigator.submitForm(this.formElement, evt?.submitter || undefined);
      } else {
        this.formElement.requestSubmit(evt?.submitter);
      }
    });
  }

  public setup(editor:ICKEditorInstance) {
    // Have a hacky way to access the editor from outside of angular.
    // This is e.g. employed to set the text from outside to reuse the same editor for different languages.
    jQuery(this.element).data('editor', editor);

    this.setupMarkingReadonlyWhenTextareaIsDisabled(editor);

    if (this.halResource?.attachments) {
      this.setupAttachmentAddedCallback(editor);
      this.setupAttachmentRemovalSignal(editor);
    }

    this.setLabel();
    return editor;
  }

  private syncToTextarea() {
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
    const textareaId = this.textareaSelector.substring(1);
    const label = jQuery(`label[for=${textareaId}]`);

    const ckContent = this.element.querySelector('.ck-content') as HTMLElement;

    ckContent.removeAttribute('aria-label');
    ckContent.setAttribute('aria-labelledby', textareaId);

    fromEvent(label, 'click')
      .pipe(this.untilDestroyed())
      .subscribe(() => ckContent.focus());
  }
}
