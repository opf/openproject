import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  forwardRef,
  Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';

@Component({
  selector: 'op-datepicker-scheduling-toggle',
  templateUrl: './datepicker-scheduling-toggle.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => OpDatePickerSchedulingToggleComponent),
    multi: true,
  }],
})
export class OpDatePickerSchedulingToggleComponent implements ControlValueAccessor {
  text = {
    scheduling: {
      title: this.I18n.t('js.scheduling.manual'),
    },
  };

  @Input() scheduleManually:boolean;

  constructor(
    private I18n:I18nService,
    private cdRef:ChangeDetectorRef,
  ) { }

  onChange = (_:boolean):void => {};

  onTouched = (_:boolean):void => {};

  registerOnChange(fn:(_:boolean) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:boolean) => void):void {
    this.onTouched = fn;
  }

  writeValue(val:boolean):void {
    this.scheduleManually = val;
    this.cdRef.markForCheck();
  }

  onToggle(value:boolean):void {
    this.writeValue(value);
    this.onChange(value);
    this.onTouched(value);
  }
}
