//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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

function createFieldsetToggleStateLabel(legend:JQuery, text:string) {
  const labelClass = 'fieldset-toggle-state-label';
  let toggleLabel = legend.find(`a span.${labelClass}`);
  const legendLink = legend.children('a');

  if (toggleLabel.length === 0) {
    toggleLabel = jQuery('<span />').addClass(labelClass)
      .addClass('hidden-for-sighted');

    legendLink.append(toggleLabel);
  }

  toggleLabel.text(` ${text}`);
}

function setFieldsetToggleState(fieldset:JQuery) {
  const legend = fieldset.children('legend');

  if (fieldset.hasClass('collapsed')) {
    createFieldsetToggleStateLabel(legend, I18n.t('js.label_collapsed'));
  } else {
    createFieldsetToggleStateLabel(legend, I18n.t('js.label_expanded'));
  }
}

function getFieldset(el:HTMLElement) {
  const element = jQuery(el);

  if (element.is('legend')) {
    return jQuery(el).parent();
  } if (element.is('fieldset')) {
    return element;
  }

  throw new Error('Cannot derive fieldset from element!');
}

function toggleFieldset(el:HTMLElement) {
  const fieldset = getFieldset(el);
  // Mark the fieldset that the user has touched it at least once
  fieldset.attr('data-touched', 'true');
  const contentArea = fieldset.find('> div').not('.form--toolbar');

  fieldset.toggleClass('collapsed');
  contentArea.slideToggle('fast');

  setFieldsetToggleState(fieldset);
}

export function setupToggableFieldsets() {
  const fieldsets = jQuery('fieldset.form--fieldset.-collapsible');

  // Toggle on click
  fieldsets.on('click', '.form--fieldset-legend', function (evt) {
    toggleFieldset(this);
    evt.preventDefault();
    evt.stopPropagation();
    return false;
  });

  // Set initial state
  fieldsets
    .each(function () {
      const fieldset = getFieldset(this);

      const contentArea = fieldset.find('> div');
      if (fieldset.hasClass('collapsed')) {
        contentArea.hide();
      }

      setFieldsetToggleState(fieldset);
    });
}
