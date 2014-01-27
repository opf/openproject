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

function addRate(date_field){
  RatesForm.add_on_top();

  var newRateRow = $(RatesForm.parentElement).down("tr");
  var validFromField = newRateRow.down('input.date')
  validFromField.value = jQuery.datepicker.formatDate('yy-mm-dd', new Date());
  newRateRow.down('td.currency').down('input').select();
}

function deleteRow(image){
  var row = image.up("tr")
  var parent=row.up();
  row.remove();
  recalculate_even_odd(parent);
}

jQuery(function(jQuery){
  jQuery(document).on("click", "body.action-edit a.delete-rate", function(){
    deleteRow(this);
    return false;
  });
});
