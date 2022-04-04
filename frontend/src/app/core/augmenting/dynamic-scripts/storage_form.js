//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

// Dynamic behavior of Storages edit page in order to enable secret field
// only if the client_id has been modified.
jQuery(document).ready(function($) {
  // Set the client_secret to disabled by default so it won't be modified
  // when touching the other attributes
  $('#storages_storage_oauth_client_secret').prop('disabled', true);

  // Trigger on client_id.focus() to enable the client_secret field
  $('#storages_storage_oauth_client_id').focus(function () {
    $('#storages_storage_oauth_client_secret').prop('disabled', false);

    // Post a clear message to the user that he has to enter the secret again,
    // but only if the old magic value is still there.
    var magic_value = "****";
    var current_value = $('#storages_storage_oauth_client_secret').val();
    if ("" == current_value || current_value.includes(magic_value)) {
      var instructions = I18n.t('js.storages.enter_oauth2_client_secret');
      $('#storages_storage_oauth_client_secret').val(instructions);
    }
  });
});
