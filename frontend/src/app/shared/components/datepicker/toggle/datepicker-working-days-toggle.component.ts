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
    useExisting: forwardRef(() => DatepickerWorkingDaysToggleComponent),
    multi: true,
  }],
})
export class DatepickerWorkingDaysToggleComponent implements ControlValueAccessor {
  @Input() ignoreNonWorkingDays:boolean;

  @Input() disabled = false;

  text = {
    ignoreNonWorkingDays: {
      title: this.I18n.t('js.work_packages.datepicker_modal.ignore_non_working_days.title'),
      yes: this.I18n.t('js.work_packages.datepicker_modal.ignore_non_working_days.true'),
      no: this.I18n.t('js.work_packages.datepicker_modal.ignore_non_working_days.false'),
    },
  };

  ignoreNonWorkingDaysOptions = [
    { value: false, title: this.text.ignoreNonWorkingDays.no },
    { value: true, title: this.text.ignoreNonWorkingDays.yes },
  ];

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
    this.writeValue(value);
    this.onChange(value);
    this.onTouched(value);
  }

  writeValue(val:boolean):void {
    this.ignoreNonWorkingDays = val;
    this.cdRef.markForCheck();
  }
}
