/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.Progress = {

  replace_with_bar: function (element) {
    var parent = $('progressbar');
    var size = parseInt(element.getAttribute('data-size'), 10) || 500;
    parent.descendants().each(function (elem) {
      elem.remove();
    });
    parent.appendChild(new Element('div', {
      'id': 'progressbar_container',
      'class': 'progressbar_container'
    }));
    new Control.ProgressBar('progressbar_container', {
      // Speed determined through laborous experimentation!
      interval: (size * (Math.log(size) * Math.log(size) * Math.log(size))) / 80000
    }).start();
  },

  attach_listeners: function () {
    if ($('progressbar') !== null && $('progressbar') !== undefined) {
      $('progressbar').select('span[data-load]').each(function (element) {
        element.observe("click", function (e) {
          if (this.getAttribute("data-load") === "true") {
            Reporting.Progress.replace_with_bar(this);
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
