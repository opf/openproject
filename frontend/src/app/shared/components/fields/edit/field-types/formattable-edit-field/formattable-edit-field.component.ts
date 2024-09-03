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
// ++

import { ChangeDetectionStrategy, Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { OpCkeditorComponent } from 'core-app/shared/components/editor/components/ckeditor/op-ckeditor.component';
import {
  ICKEditorContext,
  ICKEditorInstance,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

@Component({
  templateUrl: './formattable-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FormattableEditFieldComponent extends EditFieldComponent implements OnInit, OnDestroy {
  public readonly field = this;

  // Detect when inner component could not be initialized
  public initializationError = false;

  @ViewChild(OpCkeditorComponent, { static: true }) editor:OpCkeditorComponent;

  // Values used in template
  public isPreview = false;

  public previewHtml = '';

  private cancelled = false;

  public text:Record<string, string> = {};

  public initialContent:string;

  public ckEditorContext:ICKEditorContext = {
    resource: this.change.pristineResource,
    field: this.field.name,
    macros: 'none' as const,
    previewContext: this.previewContext,
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-unsafe-member-access
    options: { rtl: this.schema.options && this.schema.options.rtl },
    type: 'constrained',
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-call
    ...this.resource.getEditorContext(this.field.name),
  } as ICKEditorContext;

  ngOnInit():void {
    super.ngOnInit();

    this.handler.registerOnSubmit(() => Promise.resolve(this.getCurrentValue()));
    this.text = {
      attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
      save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
      cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
    };
  }

  ngOnDestroy():void {
    super.ngOnDestroy();

    if (!this.cancelled) {
      try {
        this.rawValue = this.editor?.getRawData();
      } catch (e) {
        console.error(`Failed to save CKEditor state on destroy: ${e as string}.`);
      }
    }
  }

  public onCkeditorSetup(editor:ICKEditorInstance):void {
    if (!isNewResource(this.resource)) {
      setTimeout(() => editor.editing.view.focus());
    }
  }

  public getCurrentValue():void {
    this.rawValue = this.editor.getTransformedContent();
  }

  public onContentChange(value:string):void {
    // Have the guard clause to avoid the text being set
    // in the changeset when no actual change has taken place.
    if (this.rawValue !== value) {
      this.rawValue = value;
    }
  }

  public handleUserSubmit():boolean {
    this.getCurrentValue();
    void this.handler.handleUserSubmit();

    return false;
  }

  public handleUserCancel():void {
    this.cancelled = true;
    this.handler.handleUserCancel();
  }

  private get previewContext() {
    return this.handler.previewContext(this.resource);
  }

  public reset():void {
    if (this.editor && this.editor.initialized) {
      this.editor.content = this.rawValue;

      this.cdRef.markForCheck();
    }
  }

  public get rawValue():string {
    if (this.value && this.value.raw) {
      return this.value.raw;
    }
    return '';
  }

  public set rawValue(val:string) {
    this.value = { raw: val };
  }

  public isEmpty():boolean {
    return !(this.value && this.value.raw);
  }

  protected initialize():void {
    this.initialContent = this.rawValue;

    if (isNewResource(this.resource) && this.editor) {
      // Reset CKEditor when reloading after type/form changes
      this.reset();
    }
  }
}
