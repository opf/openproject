// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
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
// See docs/COPYRIGHT.rdoc for more details.
//++

// Loaded dynamically when path matches
(function ($) {
  const globalRoles = {
    init() {
      if (globalRoles.script_applicable()) {
        globalRoles.toggle_forms_on_click();
        globalRoles.activation_and_visibility_based_on_checked($('#global_role'));
      }
    },

    toggle_forms_on_click() {
      $('#global_role').on('click', this.toggle_forms);
    },

    toggle_forms() {
      globalRoles.activation_and_visibility_based_on_checked(this);
    },

    activation_and_visibility_based_on_checked(element:any) {
      if ($(element).prop('checked')) {
        globalRoles.show_global_forms();
        globalRoles.hide_member_forms();
        globalRoles.enable_global_forms();
        globalRoles.disable_member_forms();
      } else {
        globalRoles.show_member_forms();
        globalRoles.hide_global_forms();
        globalRoles.disable_global_forms();
        globalRoles.enable_member_forms();
      }
    },

    show_global_forms() {
      $('#global_permissions').show();
    },

    show_member_forms() {
      $('#member_attributes').show();
      $('#member_permissions').show();
    },

    hide_global_forms() {
      $('#global_permissions').hide();
    },

    hide_member_forms() {
      $('#member_attributes').hide();
      $('#member_permissions').hide();
    },

    enable_global_forms() {
      $('#global_attributes input, #global_attributes input, #global_permissions input').each((ix, el) => {
        globalRoles.enable_element(el);
      });
    },

    enable_member_forms() {
      $('#member_attributes input, #member_attributes input, #member_permissions input').each((ix, el) => {
        globalRoles.enable_element(el);
      });
    },

    enable_element(element:any) {
      $(element).prop('disabled', false);
    },

    disable_global_forms() {
      $('#global_attributes input, #global_attributes input, #global_permissions input').each((ix, el) => {
        globalRoles.disable_element(el);
      });
    },

    disable_member_forms() {
      $('#member_attributes input, #member_attributes input, #member_permissions input').each((ix, el) => {
        globalRoles.disable_element(el);
      });
    },

    disable_element(element:any) {
      $(element).prop('disabled', true);
    },

    script_applicable() {
      return $('body.controller-roles.action-new, body.controller-roles.action-create').length === 1;
    },
  };
  $(document).ready(globalRoles.init);
}(jQuery));
