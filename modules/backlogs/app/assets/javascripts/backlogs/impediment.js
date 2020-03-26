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

/**************************************
  IMPEDIMENT
***************************************/

RB.Impediment = (function ($) {
  return RB.Object.create(RB.Task, {

    initialize: function (el) {
      var j;  // This ensures that we use a local 'j' variable, not a global one.

      this.$ = j = $(el);
      this.el = el;

      j.addClass("impediment"); // If node is based on #task_template, it doesn't have the impediment class yet

      // Associate this object with the element for later retrieval
      j.data('this', this);

      j.on('mouseup', '.editable', this.handleClick);
    },

    // Override saveDirectives of RB.Task
    saveDirectives: function () {
      var j, prev, statusID, data, url;

      j = this.$;
      prev = this.$.prev();
      statusID = j.parent('td').first().attr('id').split("_")[1];

      data = j.find('.editor').serialize() +
                 "&is_impediment=true" +
                 "&version_id=" + RB.constants.sprint_id +
                 "&status_id=" + statusID +
                 "&prev=" + (prev.length === 1 ? prev.data('this').getID() : '') +
                 (this.isNew() ? "" : "&id=" + j.children('.id').text());

      if (this.isNew()) {
        url = RB.urlFor('create_impediment', {sprint_id: RB.constants.sprint_id});
      }
      else {
        url = RB.urlFor('update_impediment', {id: this.getID(), sprint_id: RB.constants.sprint_id});
        data += "&_method=put";
      }

      return {
        url: url,
        data: data
      };
    }
  });
}(jQuery));
