//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

(function($) {
  $(function() {
    var revision = $('#revision-identifier-input'),
      form = revision.closest('form'),
      tag = $('#revision-tag-select'),
      branch = $('#revision-branch-select'),
      selects = tag.add(branch),
      branch_selected = branch.length > 0 && revision.val() == branch.val(),
      tag_selected = tag.length > 0 && revision.val() == tag.getValue();

    var sendForm = function() {
      selects.prop('disable', true);
      form.submit();
      selects.prop('disable', false);
    }

    /*
    If we're viewing a tag or branch, don't display it in the
    revision box
    */
    if (branch_selected || tag_selected) {
      revision.val('');
    }

    /*
    Copy the branch/tag value into the revision box, then disable
    the dropdowns before submitting the form
    */
    selects.on('change', function() {
      var select = $(this);
      revision.val(select.val());
      sendForm();
    });

    /*
    Disable the branch/tag dropdowns before submitting the revision form
    */
    revision.on('keydown', function(e) {
      if (e.keyCode == 13) {
        sendForm();
      }
    });
  });
}(jQuery));

