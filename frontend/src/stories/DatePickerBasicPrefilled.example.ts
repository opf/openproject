import * as moment from 'moment';
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  templateUrl: './DatePickerBasicPrefilled.example.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SbDatePickerBasicPrefilledExample {
  date = moment(new Date()).format('YYYY-MM-DD');
}
