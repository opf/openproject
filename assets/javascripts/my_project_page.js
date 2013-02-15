/*globals jQuery, I18n*/

var MyProjectPage = (function ($) {
  var init;

  init = function () {
    $('#users_per_role .all').click(function () {
      $('#users_per_role').html('');
    });

    $.ajaxAppend({
      trigger: '.all',
      indicator_class: 'ajax-indicator',
      load_target: '#users_per_role',
      loading_text: I18n.t("js.ajax.loading"),
      loading_class: 'box loading'
    });
  };

  $('document').ready(init);

}(jQuery));
