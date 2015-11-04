//-- copyright
// OpenProject Global Roles Plugin
//
// Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//++
(function ($, undefined) {
  var principal_roles = {
    init: function(){
      principal_roles.set_table_visibility();
      principal_roles.set_available_roles_visibility();
    },

    set_table_visibility: function(){
      if ($('#table_principal_roles_body tr').length > 0){
        $('#tab-content-global_roles .generic-table--results-container').show();
        $('#tab-content-global_roles .generic-table--no-results-container').hide();
      }
      else
      {
        $('#tab-content-global_roles .generic-table--results-container').hide();
        $('#tab-content-global_roles .generic-table--no-results-container').show();
      }
    },

    set_available_roles_visibility: function(){
      if ($('.principal_role_option').length > 0){
        $('#additional_principal_roles').show();
        $('#no_additional_principal_roles').hide();
      }
      else
      {
        $('#additional_principal_roles').hide();
        $('#no_additional_principal_roles').show();
      }
    }
  };

  $(document).ready(function () {
    $(document).ajaxStop(principal_roles.init);
    principal_roles.init();
  });
}(jQuery));
