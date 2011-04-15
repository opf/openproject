/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.Progress = {

  replace_with_bar: function (element) {
    var parent = element.up();
    var size = parseInt(element.getAttribute('data-size'), 10) || 500;
    element.remove();
    parent.appendChild(new Element('div', {
      'id': 'progressbar_container',
      'class': 'progressbar_container'
    }));
    new Control.ProgressBar('progressbar_container', {
      // Speed determined through laborous experimentation!
      interval: (size * (Math.log(size))) / 100000
    }).start();
  },

  confirm_question: function () {
    var bar = $('progressbar');
    if (bar !== null && bar !== undefined) {
      var size = bar.getAttribute('data-size');
      var question = bar.getAttribute('data-translation');
      if (confirm(question)) {
        var target = bar.getAttribute("data-target");
        Reporting.Progress.replace_with_bar(bar);
        Reporting.Controls.send_settings_data(target, Reporting.Controls.update_result_table);
      } else {
        bar.toggle();
      }
    }
  }
}

Reporting.onload(function () {
  Reporting.Progress.confirm_question();
});
