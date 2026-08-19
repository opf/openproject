export enum ReminderPreset {
  TOMORROW = 'tomorrow',
  THREE_DAYS = 'three_days',
  WEEK = 'week',
  MONTH = 'month',
  CUSTOM = 'custom',
}

export type ReminderPresetValue = `${ReminderPreset}`;

export const REMINDER_PRESET_OPTIONS = Object.values(ReminderPreset) as ReminderPreset[];
