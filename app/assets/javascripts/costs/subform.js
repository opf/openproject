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

var Subform = Class.create({
  lineIndex: 1,
  parentElement: "",
  initialize: function(rawHTML, lineIndex, parentElement) {
    this.rawHTML        = rawHTML;
    this.lineIndex      = lineIndex;
    this.parentElement  = parentElement;
  },

  parsedHTML: function() {
    return this.rawHTML.replace(/INDEX/g, this.lineIndex++);
  },

  add: function() {
    var e = $(this.parentElement);
    Element.insert(e, { bottom: this.parsedHTML()});
    recalculate_even_odd(e);
  },

  add_after: function(e) {
    Element.insert(e, { after: this.parsedHTML()});
    recalculate_even_odd($(this.parentElement));
  },

  add_on_top: function() {
    var e = $(this.parentElement);
    Element.insert(e, { top: this.parsedHTML()});
    recalculate_even_odd(e);
  }
});

function recalculate_even_odd(element) {
  $A(element.childElements()).inject(
    0,
    function(acc, e)
    {
      e.removeClassName("even");
      e.removeClassName("odd");
      e.addClassName( (acc%2==0) ? "odd" : "even"); return ++acc;
    }
  )
}
