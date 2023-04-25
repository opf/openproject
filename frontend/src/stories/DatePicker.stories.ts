import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';
import * as moment from 'moment';

import { TimezoneService } from '../app/core/datetime/timezone.service';
import { TimezoneServiceStub } from './timezone.service.stub';

import { I18nService } from '../app/core/i18n/i18n.service';
import { I18nServiceStub } from './i18n.service.stub';

import { WeekdayService } from '../app/core/days/weekday.service';
import { WeekdayServiceStub } from './weekday.service.stub';

import { DayResourceService } from '../app/core/state/days/day.service';
import { DayResourceServiceStub } from './day.service.stub';

import { ConfigurationService } from '../app/core/config/configuration.service';
import { ConfigurationServiceStub } from './configuration.service.stub';

import { States } from '../app/core/states/states.service';

import { OpBasicDatePickerModule } from '../app/shared/components/datepicker/basic-datepicker.module';
import { OpBasicSingleDatePickerComponent } from '../app/shared/components/datepicker/basic-single-date-picker/basic-single-date-picker.component'

const meta:Meta = {
  title: 'Patterns/DatePicker',
  component: OpBasicSingleDatePickerComponent,
  decorators: [
    moduleMetadata({
      imports: [
        OpBasicDatePickerModule,
      ],
      providers: [
        {
          provide: TimezoneService,
          useValue: TimezoneServiceStub, 
        },
        {
          provide: ConfigurationService,
          useValue: ConfigurationServiceStub, 
        },
        {
          provide: States,
          useValue: new States(),
        },
        {
          provide: I18nService,
          useValue: I18nServiceStub,
        },
        {
          provide: WeekdayService,
          useFactory: () => new WeekdayServiceStub(),
        },
        {
          provide: DayResourceService,
          useFactory: () => new DayResourceServiceStub(),
        },
      ],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const Single:Story = {
  render: (args) => ({
    props: {
      ...args,
    },
    template: `
      <op-basic-single-date-picker></op-basic-single-date-picker>
   `,
  }),
};

export const SingleWithValue:Story = {
  render: (args) => ({
    props: {
      ...args,
      date: moment(new Date()).format('YYYY-MM-DD'),
    },
    template: `
      <op-basic-single-date-picker
        [value]="date"
      ></op-basic-single-date-picker>
   `,
  }),
};

export const RangeWithValue:Story = {
  render: (args) => ({
    props: {
      ...args,
      dates: [
        moment(new Date()).format('YYYY-MM-DD'),
        moment(new Date()).add(4, 'days').format('YYYY-MM-DD'),
      ],
    },
    template: `
      <op-basic-range-date-picker
        [value]="dates"
      ></op-basic-range-date-picker>
   `,
  }),
};
