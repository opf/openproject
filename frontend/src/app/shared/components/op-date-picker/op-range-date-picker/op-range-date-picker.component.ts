import {
  Component,
  ChangeDetectionStrategy, Input, Output,
} from '@angular/core';
import { Instance } from 'flatpickr/dist/types/instance';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { DatePicker } from 'core-app/shared/components/op-date-picker/datepicker';
import { AbstractDatePickerDirective } from 'core-app/shared/components/op-date-picker/date-picker.directive';
import { DebouncedEventEmitter } from 'core-app/shared/helpers/rxjs/debounced-event-emitter';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

export const rangeSeparator = '-';

@Component({
  selector: 'op-range-date-picker',
  templateUrl: './op-range-date-picker.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpRangeDatePickerComponent extends AbstractDatePickerDirective {
  @Output() public onChange = new DebouncedEventEmitter<Date[]>(componentDestroyed(this));

  @Input() public initialDates:string[] = [];

  initialValue = '';

  constructor(protected timezoneService:TimezoneService) {
    super(timezoneService);

    this.initialValue = this.resolveDateArrayToString(this.initialDates);
  }

  protected initializeDatepicker():void {
    const options = {
      allowInput: true,
      appendTo: this.appendTo,
      mode: 'range',
      onChange: (selectedDates:Date[], dateStr:string) => {
        if (this.isEmpty()) {
          return;
        }

        this.inputElement.value = dateStr;
        if (selectedDates.length === 2) {
          this.onChange.emit(selectedDates);
        }
      },
      onKeyDown: (selectedDates:Date[], dateStr:string, instance:Instance, data:KeyboardEvent) => {
        if (data.which === KeyCodes.ESCAPE) {
          this.onCancel.emit();
        }
      },
    };

    let initialValue;
    if (this.isEmpty() && this.initialDates.length > 0) {
      initialValue = this.initialDates.map((date) => this.timezoneService.parseISODate(date).toDate());
    } else {
      initialValue = this.resolveDateStringToArray(this.currentValue);
    }

    this.datePickerInstance = new DatePicker(
      `#${this.id}`,
      initialValue,
      options,
    );
  }

  private resolveDateStringToArray(dates:string):string[] {
    return dates.split(` ${rangeSeparator} `).map((date) => date.trim());
  }

  private resolveDateArrayToString(dates:string[]):string {
    return dates.join(` ${rangeSeparator} `);
  }
}
