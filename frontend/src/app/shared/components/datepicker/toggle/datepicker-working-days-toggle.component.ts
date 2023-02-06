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
  selector: 'op-datepicker-working-days-toggle',
  templateUrl: './datepicker-working-days-toggle.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => OpDatePickerWorkingDaysToggleComponent),
    multi: true,
  }],
})
export class OpDatePickerWorkingDaysToggleComponent implements ControlValueAccessor {
  @Input() ignoreNonWorkingDays:boolean;

  @Input() disabled = false;

  text = {
    ignoreNonWorkingDays: {
      title: this.I18n.t('js.work_packages.datepicker_modal.ignore_non_working_days.title'),
    },
  };

  constructor(
    private I18n:I18nService,
    private cdRef:ChangeDetectorRef,
  ) {}

  onChange = (_:boolean):void => {};

  onTouched = (_:boolean):void => {};

  registerOnChange(fn:(_:boolean) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:boolean) => void):void {
    this.onTouched = fn;
  }

  onToggle(value:boolean):void {
    const ignoreNonWorkingDays = !value;
    this.writeValue(ignoreNonWorkingDays);
    this.onChange(ignoreNonWorkingDays);
    this.onTouched(ignoreNonWorkingDays);
  }

  writeValue(val:boolean):void {
    this.ignoreNonWorkingDays = val;
    this.cdRef.markForCheck();
  }
}
