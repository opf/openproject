//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

function toggleMemberFilter() {
  if (window.OpenProject.guardedLocalStorage("showFilter") === "true") {
    window.OpenProject.guardedLocalStorage("showFilter", 'false');
    hideFilter(filter);
    jQuery('#filter-member-button').removeClass('-active');
  }
  else {
    window.OpenProject.guardedLocalStorage("showFilter", 'true');
    showFilter(filter);
    jQuery('#filter-member-button').addClass('-active');
    hideAddMemberForm();
    jQuery('.simple-filters--filter:first-of-type select').focus();
  }
}

function showAddMemberForm() {
  jQuery('#members_add_form').css('display', 'block');
  jQuery('#members_add_form #principal_search').focus();
  hideFilter(filter = findFilter());
  jQuery('#filter-member-button').removeClass('-active');
  window.OpenProject.guardedLocalStorage("showFilter", 'false');
  jQuery('#add-member-button').prop('disabled', true);

  jQuery("input#member_user_ids").on("change", function() {
    var values = jQuery("input#member_user_ids").val();

    if (values.indexOf("@") != -1) {
      jQuery("#member-user-limit-warning").css("display", "block");
    } else {
      jQuery("#member-user-limit-warning").css("display", "none");
    }
  });
}

function hideAddMemberForm() {
  jQuery('#members_add_form').css('display', 'none');
  jQuery('#add-member-button').focus();
  jQuery('#add-member-button').prop('disabled', false);
}

jQuery(document).ready(function($) {
  // Show/Hide content when page is loaded
  if (window.OpenProject.guardedLocalStorage("showFilter") === "true") {
    showFilter(filter = findFilter());
  }
  else {
    hideFilter(filter = findFilter());
    // In case showFilter is not set yet
    window.OpenProject.guardedLocalStorage("showFilter", 'false');
  }

  // Toggle filter
  $('.toggle-member-filter-link').click(toggleMemberFilter);



  // Toggle editing row
  $('.toggle-membership-button').click(function() {
    var el = $(this);
    $(el.data('toggleTarget')).toggle();
    return false;
  });

  // Show add member form
  $('#add-member-button').click(showAddMemberForm);

  // Hide member form
  $('.hide-member-form-button').click(hideAddMemberForm);

  // show member form only when there's an error
  if (jQuery("#errorExplanation").text() != "") {
    showAddMemberForm();
  }

  if (jQuery('#add-member-button').attr('data-trigger-initially')) {
    showAddMemberForm();
  }
});
