//-- copyright
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
(function($) {
  $(function() {
    function observeTemplateChanges() {
      jQuery('#project-select-template').on('change', function() {
        const name = document.getElementById('project_name');
        const fieldset = document.getElementById('advanced-project-settings');

        // When the advanced settings were opened once, we assume they were changed
        // and show an alert before switching the template
        if (!fieldset.dataset.touched || window.confirm(I18n.t('js.project.confirm_template_load'))) {
          let params = new URLSearchParams(location.search);
          params.set('template_project', this.value);
          params.set('name', name.value);
          window.location.search = params.toString();
        }
      });
    }

    function focusOnName() {
      const name = document.getElementById('project_name');
      if (!name.value) {
        name.focus();
      }
    }

    function expandAdvancedOnParams() {
      const fieldset = document.getElementById('advanced-project-settings');
      let params = new URLSearchParams(location.search);

      if (params.has('parent_id')) {
        fieldset.querySelector('.form--fieldset-legend').click();
      }
    }

    observeTemplateChanges();
    expandAdvancedOnParams();
    focusOnName();
  });
}(jQuery));
