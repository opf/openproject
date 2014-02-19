//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

function swapOptions(theSel, index1, index2)
{
	var text, value;
  text = theSel.options[index1].text;
  value = theSel.options[index1].value;
  theSel.options[index1].text = theSel.options[index2].text;
  theSel.options[index1].value = theSel.options[index2].value;
  theSel.options[index2].text = text;
  theSel.options[index2].value = value;
}

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

function moveOptionUp(theSel) {
	var index = theSel.selectedIndex;
	if (index > 0) {
		swapOptions(theSel, index-1, index);
  	theSel.selectedIndex = index-1;
	}
}

function moveOptionDown(theSel) {
	var index = theSel.selectedIndex;
	if (index < theSel.length - 1) {
		swapOptions(theSel, index, index+1);
  	theSel.selectedIndex = index+1;
	}
}

function selectAllOptions(id)
{
  jQuery("#" + id + " option").attr('selected',true);
}

