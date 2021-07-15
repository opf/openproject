import {
  Component, forwardRef, Input, OnInit, ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { FormlyTemplateOptions } from '@ngx-formly/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { OpCkeditorComponent } from 'core-app/shared/components/editor/components/ckeditor/op-ckeditor.component';
import {
  ICKEditorContext,
  ICKEditorInstance,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';

@Component({
  selector: 'op-formattable-control',
  templateUrl: './formattable-control.component.html',
  styleUrls: ['./formattable-control.component.scss'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => FormattableControlComponent),
      multi: true,
    },
  ],
})
export class FormattableControlComponent implements ControlValueAccessor, OnInit {
  @Input() templateOptions:FormlyTemplateOptions;

  @ViewChild(OpCkeditorComponent, { static: true }) editor:OpCkeditorComponent;

  text:{ [key:string]:string };

  value:{ raw:string };

  disabled = false;

  touched:boolean;

  // Detect when inner component could not be initialized
  initializationError = false;

  onChange:(_any:unknown) => void = () => undefined;

  onTouch:() => void = () => undefined;

  public get ckEditorContext():ICKEditorContext {
    return {
      type: this.templateOptions.editorType,
      macros: 'none',
      options: { rtl: this.templateOptions?.rtl },
    };
  }

  constructor(
    readonly I18n:I18nService,
  ) {
  }

  ngOnInit():void {
    this.text = {
      attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
      save: this.I18n.t('js.inplace.button_save', { attribute: this.templateOptions?.name }),
      cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.templateOptions?.name }),
    };
  }

  writeValue(value:{ raw:string }):void {
    this.value = value;
  }

  registerOnChange(fn:(_:unknown) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:() => void):void {
    this.onTouch = fn;
  }

  setDisabledState(disabled:boolean):void {
    this.disabled = disabled;
    this.editor.ckEditorInstance.isReadOnly = disabled;
  }

  onContentChange(value:string) {
    const valueToEmit = { raw: value };

    this.onTouch();
    this.onChange(valueToEmit);
  }

  onCkeditorSetup(_editor:ICKEditorInstance) {
    this.editor.ckEditorInstance.ui.focusTracker.on(
      'change:isFocused',
      (evt:unknown, name:unknown, isFocused:unknown) => {
        if (!isFocused && !this.touched) {
          this.touched = true;
          this.onTouch();
        }
      },
    );
  }
}
