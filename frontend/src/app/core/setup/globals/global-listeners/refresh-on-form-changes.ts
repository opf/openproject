// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

export function refreshOnFormChanges() {
  const matches = document.querySelectorAll('.augment--refresh-on-form-changes');

  for (let i = 0; i < matches.length; i++) {
    const element = matches[i];
    const form = jQuery(element);
    const url = form.data('refreshUrl');
    const inputId = form.data('inputSelector');

    // TODO: Not all elements are available when we run here. The angular dynamic
    // components have to be instantiated first. This race condition should be removed
    // by changing how we refresh on form changes altogether.
    setTimeout(() => {
      form
        .find(inputId)
        .on('change', (e:Event) => {
          // The project selector also fires a change event when the
          // value is empty, but we don't want that here.
          const input = e.currentTarget as HTMLInputElement;
          if (input.name === 'new_project_id' && input.value === '') {
            return;
          }
          window.location.href = `${url}?${form.serialize()}`;
        });
    }, 100);
  }
}
