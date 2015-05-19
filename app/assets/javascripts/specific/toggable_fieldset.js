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

function createFieldsetToggleStateLabel(legend, text) {
  var labelClass = 'fieldset-toggle-state-label';
  var toggleLabel = legend.find('a span.' + labelClass);
  var legendLink = legend.children('a');

  if (toggleLabel.length === 0) {
    toggleLabel = jQuery("<span />").addClass(labelClass)
                                    .addClass("hidden-for-sighted");

    legendLink.append(toggleLabel);
  }

  toggleLabel.text(text);
}

function setFieldsetToggleState(fieldset) {
  var legend = fieldset.children('legend');


  if (fieldset.hasClass('collapsed')) {
    createFieldsetToggleStateLabel(legend, I18n.t('js.label_collapsed'));
  } else {
    createFieldsetToggleStateLabel(legend, I18n.t('js.label_expanded'));
  }
}

function getFieldset(el) {
  var element = jQuery(el);

  if (element.is('legend')) {
    return jQuery(el).parent();
  } else if (element.is('fieldset')) {
    return element;
  }

  throw "Cannot derive fieldset from element!";
}

function toggleFieldset(el) {
  var fieldset = getFieldset(el);
  var contentArea = fieldset.find('> div');

  fieldset.toggleClass('collapsed');
  contentArea.slideToggle('fast', null);

  setFieldsetToggleState(fieldset);
}

jQuery(document).ready(function() {
  jQuery('fieldset.form--fieldset.-collapsible').each(function() {
    var fieldset = getFieldset(this);

    setFieldsetToggleState(fieldset);
  });
});
