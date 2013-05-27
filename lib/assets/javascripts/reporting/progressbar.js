/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.Progress = {

  abort: function () {
    if (window.progressbar !== undefined && window.progressbar !== null) {
      window.progressbar.stop();
    }
  },

  replace_with_bar: function (element) {
    var parent = element.up();
    var size = parseInt(element.getAttribute('data-query-size'), 10) || 500;
    element.remove();
    window.progressbar = Reporting.Progress.add_bar_to_parent(parent);
    // Speed determined through laborous experimentation!
    window.progressbar.options.interval = (size * (Math.log(size))) / 100000;
    window.progressbar.start();
  },

  add_bar_to_parent: function (parent) {
    parent.appendChild(new Element('div', {
      'id': 'progressbar_container',
      'class': 'progressbar_container'
    }));
    return new Control.ProgressBar('progressbar_container');
  },

  confirm_question: function () {
    var bar = $('progressbar');
    if (bar !== null && bar !== undefined) {
      var size = bar.getAttribute('data-size');
      var question = bar.getAttribute('data-translation');
      if (confirm(question)) {
        var target = bar.getAttribute("data-target");
        bar.up().show();
        Reporting.Progress.replace_with_bar(bar);
        Reporting.Controls.send_settings_data(target, Reporting.Controls.update_result_table);
      } else {
        bar.toggle();
      }
    }
  }
};

Reporting.onload(function () {
  Reporting.Progress.confirm_question();
});
