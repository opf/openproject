/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.Progress = {

  confirm_question: function () {
    if ($('progressbar') !== null && $('progressbar') !== undefined) {
      var size = $('progressbar').getAttribute('data-size');
      var question = $('progressbar').getAttribute('data-translation');
      if (confirm(question)) {
        Reporting.Controls.send_settings_data($('progressbar').getAttribute("data-target"), Reporting.Controls.update_result_table);
      } else {
        $('progressbar').toggle();
      }
    }
  }
}

Reporting.onload(function () {
  Reporting.Progress.confirm_question();
});
