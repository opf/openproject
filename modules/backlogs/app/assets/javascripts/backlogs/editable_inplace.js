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
