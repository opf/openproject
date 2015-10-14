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

function WorkPackageShowPage() {}

WorkPackageShowPage.prototype = {

  wpId: 819,
  focusElement: $('#work-package-subject .focus-input'),
  focusElementValue: $('#work-package-subject span.inplace-edit--read-value > span:first-child'),
  editableFields: $$('.focus-input'),

  editActions: {
    container: $('.work-packages--edit-actions'),
    cancel: $('.work-packages--edit-actions .button:last-child')
  },

  toolBar: {
    edit: $('.button.icon-edit'),
    overview: $('#work-packages-details-view-button'),
    watch: $('[id*="watch"]'),
    dropDown: $('#action-show-more-dropdown-menu > button'),
    filter: $('#work-packages-filter-toggle-button'),
    settings: $('#work-packages-settings-button'),
    addWorkPackage: $('.button.add-work-package'),
    listView: $('#work-packages-list-view-button')
  },

  get: function() {
    browser.get('/work_packages/' + this.wpId + '/activity');
  }
};

module.exports = WorkPackageShowPage;
