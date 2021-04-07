import { Component, forwardRef, Input, OnInit, ViewChild } from '@angular/core';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { FormlyTemplateOptions } from "@ngx-formly/core";
import { ICKEditorContext, ICKEditorInstance } from "core-app/modules/common/ckeditor/ckeditor-setup.service";
import { NG_VALUE_ACCESSOR } from "@angular/forms";
import { OpCkeditorComponent } from "core-app/modules/common/ckeditor/op-ckeditor.component";

@Component({
  selector: 'op-formattable-control',
  templateUrl: './formattable-control.component.html',
  styleUrls: ['./formattable-control.component.scss'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => FormattableControlComponent),
      multi: true
    }
  ]
})
export class FormattableControlComponent implements OnInit {
  @Input()
  templateOptions:FormlyTemplateOptions;

  @ViewChild(OpCkeditorComponent, { static: true }) editor:OpCkeditorComponent;

  text:{[key:string]: string};
  value:{raw:string};
  disabled = false;
  touched:boolean;
  // Detect when inner component could not be initialized
  initializationError = false;
  onChange = (_:any) => { }
  onTouch = () => { }

  public get ckEditorContext():ICKEditorContext {
    return {
      // TODO: Can the current editor work without resource??
      // resource: this.change.pristineResource,
      macros: 'none' as const,
      // TODO: Do we need a previewContext
      // previewContext: this.previewContext,
      options: { rtl: this.templateOptions?.rtl }
    };
  }

  constructor(
    readonly I18n:I18nService,
  ) { }

  ngOnInit(): void {
    this.text = {
      attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
      save: this.I18n.t('js.inplace.button_save', { attribute: this.templateOptions?.name }),
      cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.templateOptions?.name })
    };
  }

  writeValue(value:{raw:string}):void {
    this.value = value;
  }

  registerOnChange(fn: (_: any) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: any): void {
    this.onTouch = fn;
  }

  setDisabledState(disabled: boolean): void {
    this.disabled = disabled;
    this.editor.ckEditorInstance.isReadOnly = disabled;
  }

  onContentChange(value:string) {
    this.editor
      .getTransformedContent()
      .then((val) => {
        const valueToEmit = {raw: val};

        this.onTouch();
        this.onChange(valueToEmit);
      });
  }

  onCkeditorSetup(editor:ICKEditorInstance) {
    this.editor.ckEditorInstance.ui.focusTracker.on( 'change:isFocused', ( evt:any, name:any, isFocused:any ) => {
      if (!isFocused && !this.touched) {
        this.touched = true;
        this.onTouch();
      }
    } );
    // TODO: Check if it is new without resource
    /*if (!this.resource.isNew) {
      setTimeout(() => editor.editing.view.focus());
    }*/
  }
}
