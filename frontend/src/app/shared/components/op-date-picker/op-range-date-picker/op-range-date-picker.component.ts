import {
  ChangeDetectionStrategy,
  Component,
  Input,
  Output,
} from '@angular/core';
import { Instance } from 'flatpickr/dist/types/instance';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { DatePicker } from 'core-app/shared/components/op-date-picker/datepicker';
import { AbstractDatePickerDirective } from 'core-app/shared/components/op-date-picker/date-picker.directive';
import { DebouncedEventEmitter } from 'core-app/shared/helpers/rxjs/debounced-event-emitter';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';

export const rangeSeparator = '-';

@Component({
  selector: 'op-range-date-picker',
  templateUrl: './op-range-date-picker.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpRangeDatePickerComponent extends AbstractDatePickerDirective {
  @Output() public changed = new DebouncedEventEmitter<string[]>(componentDestroyed(this));

  @Input() public initialDates:string[] = [];

  initialValue = '';

  protected initializeDatepicker():void {
    this.initialDates = this.initialDates || [];
    this.initialValue = this.resolveDateArrayToString(this.initialDates);

    const options = {
      allowInput: true,
      appendTo: this.appendTo,
      mode: 'range' as const,
      onChange: (selectedDates:Date[], dateStr:string) => {
        if (this.isEmpty()) {
          return;
        }

        this.inputElement.value = dateStr;
        if (selectedDates.length === 2) {
          this.changed.emit(this.resolveDateStringToArray(dateStr));
        }
      },
      onKeyDown: (selectedDates:Date[], dateStr:string, instance:Instance, data:KeyboardEvent) => {
        if (data.which === KeyCodes.ESCAPE) {
          this.canceled.emit();
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
      null,
      this.configurationService,
    );
  }

  // eslint-disable-next-line class-methods-use-this
  onKeyDown():boolean {
    // Disable any manual user input as it most likely return in a wrong format
    return false;
  }

  // eslint-disable-next-line class-methods-use-this
  private resolveDateStringToArray(dates:string):string[] {
    return dates.split(` ${rangeSeparator} `).map((date) => date.trim());
  }

  // eslint-disable-next-line class-methods-use-this
  private resolveDateArrayToString(dates:string[]):string {
    return dates.join(` ${rangeSeparator} `);
  }
}
