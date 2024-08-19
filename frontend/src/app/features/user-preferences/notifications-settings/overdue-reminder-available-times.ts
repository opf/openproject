export function reminderAvailableTimeframes():{ value:string, title:string }[] {
  return [
    {
      value: 'PT0S',
      title: window.I18n.t('js.notifications.settings.reminders.timeframes.normal.PT0S'),
    },
    {
      value: 'P1D',
      title: window.I18n.t('js.notifications.settings.reminders.timeframes.normal.P1D'),
    },
    {
      value: 'P3D',
      title: window.I18n.t('js.notifications.settings.reminders.timeframes.normal.P3D'),
    },
    {
      value: 'P7D',
      title: window.I18n.t('js.notifications.settings.reminders.timeframes.normal.P7D'),
    },
  ];
}

export function overDueReminderTimes():{ value:string, title:string }[] {
  return [
    {
      value: 'P1D',
      title: window.I18n.t('js.notifications.settings.reminders.timeframes.overdue.P1D'),
    },
    {
      value: 'P3D',
      title: window.I18n.t('js.notifications.settings.reminders.timeframes.overdue.P3D'),
    },
    {
      value: 'P7D',
      title: window.I18n.t('js.notifications.settings.reminders.timeframes.overdue.P7D'),
    },
  ];
}
