import * as moment from 'moment';
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  templateUrl: './DatePickerRangePrefilled.example.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SbDatePickerRangePrefilledExample {
  dates = [
    moment(new Date()).format('YYYY-MM-DD'),
    moment(new Date()).add(4, 'days').format('YYYY-MM-DD'),
  ];
}
