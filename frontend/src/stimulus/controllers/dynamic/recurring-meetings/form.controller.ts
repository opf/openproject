import OpMeetingsFormController from 'core-stimulus/controllers/dynamic/meetings/form.controller';

export default class OpRecurringMeetingsFormController extends OpMeetingsFormController {
  static values = {
    persisted: Boolean,
  };

  declare persistedValue:boolean;

  async updateFrequencyText() {
    const data = new FormData(this.element as HTMLFormElement);
    const urlSearchParams = new URLSearchParams();
    [
      'start_date',
      'start_time_hour',
      'frequency',
      'interval',
      'monthly_day',
      'monthly_ordinal',
      'monthly_weekday',
      'time_zone',
    ].forEach((name) => {
      const key = `meeting[${name}]`;
      urlSearchParams.append(key, data.get(key) as string);
    });

    const { turboRequests, pathHelperService } = await this.services;
    void turboRequests
      .request(
        `${pathHelperService.staticBase}/recurring_meetings/humanize_schedule?${urlSearchParams.toString()}`,
        {
          headers: {
            Accept: 'text/vnd.turbo-stream.html',
          },
        },
      );
  }

  async updateTimezoneText() {
    // We don't update the timezone text on editing recurring meetings
    if (this.persistedValue) {
      return;
    }

    await super.updateTimezoneText();
  }
}
