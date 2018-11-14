//-- copyright
// OpenProject Backlogs Plugin
//
// Copyright (C)2013-2014 the OpenProject Foundation (OPF)
// Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
// Copyright (C)2010-2011 friflaj
// Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
// Copyright (C)2009-2010 Mark Maglana
// Copyright (C)2009 Joe Heck, Nate Lowrie
//
// This program is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License version 3.
//
// OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
// The copyright follows:
// Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
// Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

RB.EditableInplace = (function ($) {
  return RB.Object.create(RB.Model, {

    displayEditor: function (editor) {
      this.$.addClass("editing");
      editor.find(".editor").bind('keyup', this.handleKeyup);
    },

    getEditor: function () {
      // Create the model editor container if it does not yet exist
      var editor = this.$.children(".editors").first().html('');

      if (editor.length === 0) {
        editor = $("<div class='editors'></div>").appendTo(this.$);
      }
      return editor;
    },

    handleKeyup: function (e) {
      var j, that;

      j = $(this).parents('.model').first();
      that = j.data('this');

      switch (e.which) {
      case 13: // Enter
        that.saveEdits();
        break;
      case 27: // ESC
        that.cancelEdit();
        break;
      default:
        return true;
      }
    }
  });
}(jQuery));
