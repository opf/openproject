var Administration = (function ($) {
  var update_default_language_options,
    init_language_selection_handling,
    toggle_default_language_select;

  update_default_language_options = function (input) {
    var default_language_select = $('#setting_default_language select'),
      default_language_select_active;

    if (input.attr('checked')) {
      default_language_select.find('option[value="' + input.val() + '"]').removeAttr('disabled');
    } else {
      default_language_select.find('option[value="' + input.val() + '"]').attr('disabled', 'disabled');
    }

    default_language_select_active = default_language_select.find('option:not([disabled="disabled"])');

    toggle_disabled_state(default_language_select_active.length === 0);

    if (default_language_select_active.length === 1) {
      default_language_select_active.attr('selected', true);
    } else if (default_language_select.val() === input.val() && !input.attr('checked')) {
      default_language_select_active.first().attr('selected', true);
    }
  };

  toggle_disabled_state = function (active) {
    jQuery('#setting_default_language select').attr('disabled', active)
      .closest('form')
      .find('input:submit')
      .attr('disabled', active);
  };

  init_language_selection_handling = function () {
    jQuery('#setting_available_languages input:not([checked="checked"])').each(function (index, input) {
      update_default_language_options($(input));
    });
    jQuery('#setting_available_languages input').click(function () {
      update_default_language_options($(this));
    });
  };

  return {
    init_language_selection_handling: init_language_selection_handling
  };
}(jQuery));

Administration.init_language_selection_handling();