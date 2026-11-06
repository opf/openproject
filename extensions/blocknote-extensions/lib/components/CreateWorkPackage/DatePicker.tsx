import { useEffect, useEffectEvent, useMemo, useRef, useState } from 'react';
import { flushSync } from 'react-dom';
import flatpickr from 'flatpickr';
import type { DayElement, Instance } from 'flatpickr/dist/types/instance';
import { useAnchoredPopover } from '../WorkPackage/anchoredPopover';
import { CalendarStyles, TextControl } from './atoms';
import {
  calendarLocaleOf,
  formatDateTime,
  isoDateOf,
  isoToWallClockDate,
  localDateOf,
  parseDateTime,
  uses24HourClock,
  wallClockDateToISO,
} from './dateTime';
import { isNonWorkingDay, loadNonWorkingDays, useDatePickerSettings } from './datePickerSettings';
import type { DatePickerSettings } from './datePickerSettings';

const OPENPROJECT_MOBILE_WIDTH = 544;

const CALENDAR_OFFSET = 2;

const VALUE_FORMAT = 'value';

interface DatePickerProps {
  id:string;
  withTime:boolean;
  value:string;
  placeholder?:string;
  invalid:boolean;
  describedBy?:string;
  onChange:(value:string) => void;
}

interface CalendarValue {
  dateOf:(value:string) => Date | null;
  valueOf:(date:Date) => string;
  textOf:(date:Date) => string;
  parse:(text:string) => Date | null;
}

const dateValue:CalendarValue = {
  dateOf: localDateOf,
  valueOf: isoDateOf,
  textOf: isoDateOf,
  parse: localDateOf,
};

function dateTimeValue(settings:DatePickerSettings):CalendarValue {
  const valueOf = (date:Date) => wallClockDateToISO(date, settings.timeZone) ?? '';
  const dateOf = (value:string) => isoToWallClockDate(value, settings.timeZone);

  return {
    dateOf,
    valueOf,
    textOf: (date) => formatDateTime(valueOf(date), settings),
    parse: (text) => {
      const value = parseDateTime(text, settings);
      return value ? dateOf(value) : null;
    },
  };
}

const keepEscape = (event:KeyboardEvent) => {
  if (event.key === 'Escape') event.stopPropagation();
};

const controlPropsOf = ({ id, placeholder, invalid, describedBy }:DatePickerProps) => ({
  id,
  autoComplete: 'off',
  placeholder,
  'aria-invalid': invalid || undefined,
  'aria-describedby': describedBy,
});

const CalendarPicker = (props:DatePickerProps) => {
  const { id, withTime, value, onChange } = props;
  const settings = useDatePickerSettings();
  const calendarValue = useMemo(
    () => settings && (withTime ? dateTimeValue(settings) : dateValue),
    [settings, withTime]
  );
  const [input, setInput] = useState<HTMLInputElement | null>(null);
  const [calendar, setCalendar] = useState<Instance | null>(null);
  const [shownMonth, setShownMonth] = useState<string | null>(null);
  const calendarRef = useRef<HTMLElement | null>(null);
  const valueRef = useRef(value);

  useAnchoredPopover({
    anchorEl: input,
    popoverRef: calendarRef,
    placement: 'below',
    offset: CALENDAR_OFFSET,
    resizeKey: shownMonth,
  });

  const commit = useEffectEvent((dates:Date[], { valueOf }:CalendarValue) => {
    const next = dates[0] ? valueOf(dates[0]) : '';
    if (next === valueRef.current) return;

    valueRef.current = next;
    onChange(next);
  });

  useEffect(() => {
    if (!settings || !calendarValue || !input) return;

    let active = true;
    const dayLabel = new Intl.DateTimeFormat(settings.locale, { dateStyle: 'long' });

    const showMonth = (instance:Instance) => {
      // Synchronously, so the calendar is positioned before it is painted.
      flushSync(() => setShownMonth(`${instance.currentYear}-${instance.currentMonth}`));
      void loadNonWorkingDays(instance.currentYear).then(() => {
        if (active) instance.redraw();
      });
    };

    const instance = flatpickr(input, {
      enableTime: withTime,
      time_24hr: uses24HourClock(settings),
      allowInput: true,
      disableMobile: true,
      locale: calendarLocaleOf(settings.locale, settings.firstDayOfWeek),
      dateFormat: VALUE_FORMAT,
      defaultDate: calendarValue.dateOf(valueRef.current) ?? undefined,
      formatDate: (date, format) => (format === VALUE_FORMAT ? calendarValue.textOf(date) : dayLabel.format(date)),
      // flatpickr handles a missing date, although its types do not allow one.
      parseDate: (text) => calendarValue.parse(text)!,
      appendTo: input.parentElement ?? undefined,
      position: () => undefined,
      onOpen: (_dates, _text, opened) => showMonth(opened),
      onMonthChange: (_dates, _text, shown) => showMonth(shown),
      onYearChange: (_dates, _text, shown) => showMonth(shown),
      onChange: (dates) => commit(dates, calendarValue),
      onClose: (dates) => {
        setShownMonth(null);
        commit(dates, calendarValue);
      },
      onDayCreate: (_dates, _text, _instance, day:DayElement) => {
        if (isNonWorkingDay(day.dateObj)) day.classList.add('flatpickr-non-working-day_enabled');
      },
    });

    const { calendarContainer } = instance;
    calendarContainer.classList.add('op-bn-create-wp-calendar');
    calendarContainer.dataset.testid = `${id}-calendar`;
    calendarContainer.addEventListener('keydown', keepEscape);
    calendarRef.current = calendarContainer;
    setCalendar(instance);

    return () => {
      active = false;
      calendarRef.current = null;
      setCalendar(null);
      instance.destroy();
    };
  }, [settings, calendarValue, input, withTime, id]);

  useEffect(() => {
    if (!calendar || !calendarValue || value === valueRef.current) return;

    valueRef.current = value;
    const date = calendarValue.dateOf(value);
    if (date) calendar.setDate(date, false);
    else calendar.clear(false);
  }, [calendar, calendarValue, value]);

  return (
    <>
      <CalendarStyles />
      <TextControl
        {...controlPropsOf(props)}
        ref={setInput}
        type="text"
        disabled={!settings}
        onKeyDown={(event) => {
          if (event.key === 'Escape' && calendar?.isOpen) {
            event.stopPropagation();
            calendar.close();
          } else if (event.key === 'Enter') {
            // flatpickr blurs the field on Enter, which prevents the implicit submit.
            event.preventDefault();
            event.currentTarget.form?.requestSubmit();
          }
        }}
      />
    </>
  );
};

export const DatePicker = (props:DatePickerProps) => {
  if (props.withTime || window.innerWidth >= OPENPROJECT_MOBILE_WIDTH) return <CalendarPicker {...props} />;

  return (
    <TextControl
      {...controlPropsOf(props)}
      type="date"
      value={props.value}
      onChange={(event) => props.onChange(event.target.value)}
    />
  );
};
