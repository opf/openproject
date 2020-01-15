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

function moveOptions(sourceId, destId) {
  var sourceSelection = jQuery('#' + sourceId);
  var destSelection = jQuery('#' + destId);

  var selectedOptions = sourceSelection.find('option:selected');

  selectedOptions.each(function() {
    var option = jQuery('<option>', { value: this.value,
                                      text: this.text });

    destSelection.append(option);
    this.remove();
  });
}

function swapOptions(option1, option2) {
  if (option1.length == 1 && option2.length == 1) {
    option2.after(option1);
  }
}

function moveOptionUp(selectionId) {
  var selection = jQuery('#' + selectionId);
  var selectedOptions = selection.find('option:selected');

  swapOptions(selectedOptions.prev(), selectedOptions);
}

function moveOptionDown(selectionId) {
  var selection = jQuery('#' + selectionId);
  var selectedOptions = selection.find('option:selected');

  swapOptions(selectedOptions, selectedOptions.next());
}

function selectAllOptions(id) {
  jQuery("#" + id + " option").attr('selected',true);
}
