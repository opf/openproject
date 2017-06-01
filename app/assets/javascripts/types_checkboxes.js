//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

(function($) {
  var TypesCheckboxes = function () {
    this.init();
  };

  TypesCheckboxes.prototype = $.extend(TypesCheckboxes.prototype, {
    init: function () {
      this.append_checkbox_listeners();
      this.append_check_uncheck_all_listeners();
      if (this.everything_unchecked()) {
        this.check_and_disable_standard_type();
      }
    },

    append_checkbox_listeners: function () {
      var self = this;
      this.all_checkboxes().on("change", function () {
        if (self.everything_unchecked()) {
          self.check_and_disable_standard_type();
          self.display_explanation();
        } else {
          self.hide_explanation();
          self.enable_standard_type();
        }
      });
    },

    append_check_uncheck_all_listeners: function () {
      var self = this;
      $("#project_types #check_all_types").click(function (event) {
        self.enable_all_checkboxes();
        self.check(self.all_checkboxes());
        self.hide_explanation();
        event.preventDefault();
      });
      $("#project_types #uncheck_all_types").click(function (event) {
        self.enable_all_checkboxes();
        self.uncheck(self.all_except_standard());
        self.check_and_disable_standard_type();
        self.display_explanation();
        event.preventDefault();
      });
    },

    everything_unchecked: function () {
      return !(this.all_except_standard().filter(":checked").length > 0);
    },

    check_and_disable_standard_type: function () {
      var standard = this.standard_check_boxes();
      this.check($(standard));
      this.disable($(standard));
    },

    enable_standard_type: function () {
      this.enable(this.standard_check_boxes());
    },

    enable_all_checkboxes: function () {
      this.enable(this.all_checkboxes());
    },

    check: function (boxes) {
      $(boxes).prop("checked", true);
    },

    uncheck: function (boxes) {
      $(boxes).prop("checked", false);
    },

    disable: function (boxes) {
      var self = this;
      $(boxes).prop('disabled', true);
      $(boxes).each(function (ix, item) {
        self.hidden_type_field($(item)).prop("value", $(item).prop("value"));
      });
    },

    enable: function (boxes) {
      var self = this;
      $(boxes).prop('disabled', false);
      $(boxes).each(function (ix, item) {
        self.hidden_type_field($(item)).prop("value", "");
      });
    },

    display_explanation: function () {
      $("#types_flash_notice").show();
    },

    hide_explanation: function () {
      $("#types_flash_notice").hide();
    },

    all_checkboxes: function () {
      return $(".types :input[type='checkbox']");
    },

    all_except_standard: function () {
      return $(".types :input[type='checkbox'][data-standard='false']");
    },

    standard_check_boxes: function () {
      return $(".types :input[type='checkbox'][data-standard='true']");
    },

    hidden_type_field: function (for_box) {
      return $(".types :input[type='hidden'][data-for='" + $(for_box).prop("id") + "']");
    }
  });

  $('document').ready(function () {
    new TypesCheckboxes();
  });
})(jQuery);
