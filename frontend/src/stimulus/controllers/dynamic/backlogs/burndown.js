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

RB.Burndown = (function ($) {
  return RB.Object.create({

    initialize: function (el) {
      this.$ = $(el);
      this.el = el;

      // Associate this object with the element for later retrieval
      this.$.data('this', this);

      // Observe menu items
      this.$.click(this.show);
    },

    setSprintId : function (sprintId) {
      this.sprintId = sprintId;
    },

    getSprintId : function (){
      return this.sprintId;
    },

    show: function (e) {
      e.preventDefault();

      if ($("#charts").length === 0) {
        $('<div id="charts"></div>').appendTo("body");
      }
      $('#charts').html("<div class='loading'>" + RB.i18n.generating_graph + "</div>");

      var url = RB.urlFor('show_burndown_chart', { sprint_id: $(this).data('this').sprintId, project_id: RB.constants.project_id});
      window.open(url);
    }
  });
}(jQuery));
