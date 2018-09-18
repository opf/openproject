/**
 * Our application is still a hybrid one, meaning most routes are still
 * handled by Rails. As such, we disable the default link-hijacking that
 * Angular's HTML5-mode with <base href="/"> results in
 * @param evt
 * @param target
 */
export function augmentedDatePicker(evt:JQueryEventObject, target:JQuery) {
  if (target.hasClass('-augmented-datepicker')) {
    target
      .attr('autocomplete', 'off') // Disable autocomplete for those fields
      .datepicker() // Create datepicker with defaults
      .datepicker('show'); // And show immediately since the click is not yet wired to the datepicker instance
  }
}
