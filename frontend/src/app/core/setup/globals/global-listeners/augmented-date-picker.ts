import { DatePicker } from "core-app/modules/common/op-date-picker/datepicker";

/**
 * Our application is still a hybrid one, meaning most routes are still
 * handled by Rails. As such, we disable the default link-hijacking that
 * Angular's HTML5-mode with <base href="/"> results in
 * @param evt
 * @param target
 */
export function augmentedDatePicker(evt:JQuery.TriggeredEvent, target:JQuery) {
  if (target.hasClass('-augmented-datepicker')) {
    target
      .attr('autocomplete', 'off'); // Disable autocomplete for those fields

    window.OpenProject.getPluginContext()
      .then(context => {
        var datePicker = new DatePicker(
          '.-augmented-datepicker',
          target.val(),
          {
            weekNumbers: true,
            allowInput: true
          },
          target[0],
          context.services.configurationService
        );
        datePicker.show();
      });
  }
}
