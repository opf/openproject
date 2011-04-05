/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.Progress = {

  attach_listeners: function () {
    if ($('progressbar') !== null && $('progressbar') !== undefined) {
      $('progressbar').select('span[data-load]').each(function (element) {
        element.observe("click", function (e) {
          if (this.getAttribute("data-load") === "true") {
            Reporting.Controls.send_settings_data(this.getAttribute("data-target"), Reporting.Controls.update_result_table);
          } else {
            $('progressbar').toggle();
          }
        });
      });
    }
  }
};

Reporting.onload(function () {
  Reporting.Progress.attach_listeners();
});
