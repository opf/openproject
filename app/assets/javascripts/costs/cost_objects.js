//-- copyright
// OpenProject Costs Plugin
//
// Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//++

function deleteBudgetItem(id, field) {
  $(id + '_' + field).value = 0;
  $(id).hide();
}

function deleteMaterialBudgetItem(id) { deleteBudgetItem(id, 'units') }
function deleteLaborBudgetItem(id) { deleteBudgetItem(id, 'hours') }

function confirmChangeType(text, select, originalValue) {
  if (originalValue == "") return true;
  var ret = confirm(text);
  if (!ret) select.setValue(originalValue);
  return ret;
}

jQuery(function($) {
  $(window).load(function () {
    $('.action_menu_specific > .icon-edit').click(function () {
      var scrollToId = "#update",
          focusId = "#cost_object_description";
      $(scrollToId).show();
      $('html, body').animate({
          scrollTop: $(scrollToId).offset().top
      }, 500);
      $(focusId).focus();
      return false;
    });
  });
});
