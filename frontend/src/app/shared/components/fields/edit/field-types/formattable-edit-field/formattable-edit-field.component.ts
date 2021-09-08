// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {
  ChangeDetectionStrategy, Component, OnInit, ViewChild,
} from '@angular/core';
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
export class FormattableEditFieldComponent extends EditFieldComponent implements OnInit {
  public readonly field = this;

  // Detect when inner component could not be initalized
  public initializationError = false;

  @ViewChild(OpCkeditorComponent, { static: true }) editor:OpCkeditorComponent;

  // Values used in template
  public isPreview = false;

  public previewHtml = '';

  public text:Record<string, string> = {};

  public initialContent:string;

  public ckEditorContext:ICKEditorContext = {
    resource: this.change.pristineResource,
    macros: 'none' as const,
    previewContext: this.previewContext,
    options: { rtl: this.schema.options && this.schema.options.rtl },
    type: 'constrained',
    ...this.resource.getEditorContext(this.field.name),
  };

  ngOnInit():void {
    super.ngOnInit();

    this.handler.registerOnSubmit(() => this.getCurrentValue());
    this.text = {
      attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
      save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
      cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
    };
  }

  public onCkeditorSetup(editor:ICKEditorInstance):void {
    if (!isNewResource(this.resource)) {
      setTimeout(() => editor.editing.view.focus());
    }
  }

  public getCurrentValue():Promise<void> {
    return this.editor
      .getTransformedContent()
      .then((val) => {
        this.rawValue = val;
      });
  }

  public onContentChange(value:string):void {
    // Have the guard clause to avoid the text being set
    // in the changeset when no actual change has taken place.
    if (this.rawValue !== value) {
      this.rawValue = value;
    }
  }

  public handleUserSubmit():boolean {
    this.getCurrentValue()
      .then(() => {
        this.handler.handleUserSubmit();
      });

    return false;
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
