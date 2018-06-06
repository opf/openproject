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

jQuery(document).ready(function($) {
  $("#tab-content-members").submit('#members_add_form', function () {
    var error = $('.errorExplanation, .flash');
    if (error) {
      error.remove();
    }
  });

  // Show/Hide content when page is loaded
  if (localStorage.getItem("showFilter") === "true") {
    showFilter(filter = findFilter());
  }
  else {
    hideFilter(filter = findFilter());
    // In case showFilter is not set yet
    localStorage.setItem("showFilter", 'false')
  }

  // show member form only when there's an error
  if (jQuery("#errorExplanation").text() != "") {
    showAddMemberForm();
  }

  if (jQuery('#add-member-button').attr('data-trigger-initially')) {
    showAddMemberForm();
  }
});

function toggleMemberFilter() {
  if (localStorage.getItem("showFilter") === "true") {
    localStorage.setItem("showFilter", 'false');
    hideFilter(filter);
    jQuery('#filter-member-button').removeClass('-active');
  }
  else {
    localStorage.setItem("showFilter", 'true');
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
  localStorage.setItem("showFilter", 'false');
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
