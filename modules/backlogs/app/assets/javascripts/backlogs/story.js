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

/**************************************
  STORY
***************************************/
RB.Story = (function ($) {
  return RB.Object.create(RB.WorkPackage, RB.EditableInplace, {
    initialize: function (el) {
      this.$ = $(el);
      this.el = el;

      // Associate this object with the element for later retrieval
      this.$.data('this', this);
      this.$.on('mouseup', '.editable', this.handleClick);
    },

    /**
     * Callbacks from model.js
     **/
    beforeSave: function () {
      this.refreshStory();
    },

    afterCreate: function (data, textStatus, xhr) {
      this.refreshStory();
    },

    afterUpdate : function (data, textStatus, xhr) {
      this.refreshStory();
    },

    refreshed: function () {
      this.refreshStory();
    },
    /**/

    editDialogTitle: function () {
      return "Story #" + this.getID();
    },

    editorDisplayed: function (editor) { },

    getPoints: function () {
      var points = parseInt(this.$.find('.story_points').first().text(), 10);
      return isNaN(points) ? 0 : points;
    },

    getType: function () {
      return "Story";
    },

    markIfClosed: function () {
      // Do nothing
    },

    newDialogTitle: function () {
      return "New Story";
    },

    refreshStory : function () {
      this.recalcVelocity();
    },

    recalcVelocity: function () {
      this.$.parents(".backlog").first().data('this').refresh();
    },

    saveDirectives: function () {
      var url, prev, sprintId, data;

      prev = this.$.prev();
      sprintId = this.$.parents('.backlog').data('this').isSprintBacklog() ?
                   this.$.parents('.backlog').data('this').getSprint().data('this').getID() :
                   '';

      data = "prev=" +
             (prev.length === 1 ?  prev.data('this').getID() : '') +
             "&fixed_version_id=" + sprintId;

      if (this.$.find('.editor').length > 0) {
        data += "&" + this.$.find('.editor').serialize();
      }

      //TODO: this might be unsave in case the parent of this story is not the
      //      sprint backlog, then we dont have a sprintId an cannot generate a
      //      valid url - one option might be to take RB.constants.sprint_id
      //      hoping it exists
      if (this.isNew()) {
        url = RB.urlFor('create_story', {sprint_id: sprintId});
      } else {
        url = RB.urlFor('update_story', {id: this.getID(), sprint_id: sprintId});
        data += "&_method=put";
      }

      return {
        url: url,
        data: data
      };
    },

    beforeSaveDragResult: function () {
      // Do nothing
    }
  });
}(jQuery));
