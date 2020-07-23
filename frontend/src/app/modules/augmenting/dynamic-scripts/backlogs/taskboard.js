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

/***************************************
  TASKBOARD
***************************************/

RB.Taskboard = (function ($) {
  return RB.Object.create(RB.Model, {

    initialize: function (el) {
      var self = this; // So we can bind the event handlers to this object

      this.$ = $(el);
      this.el = el;

      // Associate this object with the element for later retrieval
      this.$.data('this', this);

      // Initialize column widths
      this.colWidthUnit = $(".swimlane").width();
      this.defaultColWidth = 1;
      this.loadColWidthPreference();
      this.updateColWidths();

      $("#col_width input").keyup(function (e) {
        if (e.which === 13) {
          self.updateColWidths();
        }
      });

      this.initializeTasks();
      this.initializeImpediments();

      this.initializeNewButtons();
      this.initializeSortables();

      this.initializeTaskboardMenus();
    },

    initializeNewButtons : function () {
      this.$.find('#tasks .add_new.clickable').click(this.handleAddNewTaskClick);
      this.$.find('#impediments .add_new.clickable').click(this.handleAddNewImpedimentClick);
    },

    initializeSortables : function () {
      this.$.find('#impediments .list').sortable({
        placeholder: 'placeholder',
        start:  this.dragStart,
        stop:   this.dragStop,
        update: this.dragComplete,
        cancel: '.prevent_edit'
      }).sortable('option', 'connectWith', '#impediments .list');
      $('#impediments .list').disableSelection();

      var list, augmentList, self = this;

      list = this.$.find('#tasks .list');

      augmentList = function () {
        $(list.splice(0, 50)).sortable({
          placeholder: 'placeholder',
          start:  self.dragStart,
          stop:   self.dragStop,
          update: self.dragComplete,
          cancel: '.prevent_edit'
        }).sortable('option', 'connectWith', '#tasks .list');
        $('#tasks .list').disableSelection();

        if (list.length > 0) {
          /*globals setTimeout*/
          setTimeout(augmentList, 10);
        }
      };
      augmentList();
    },

    initializeTasks : function () {
      this.$.find('.task').each(function (index) {
        RB.Factory.initialize(RB.Task, this);
      });
    },

    initializeImpediments : function () {
      this.$.find('.impediment').each(function (index) {
        RB.Factory.initialize(RB.Impediment, this);
      });
    },

    initializeTaskboardMenus : function () {
      var toggleOpen = "open icon-pulldown-up icon-pulldown";

      $(".backlog .menu > div.menu-trigger").on("click", function() {
        $(this).toggleClass(toggleOpen);
      });

      $(".backlog .menu > ul.items li.item").on("click", function() {
        $(this).closest(".menu").find("div.menu-trigger").toggleClass(toggleOpen);
      });
    },

    dragComplete: function (e, ui) {
      // Handler is triggered for source and target. Thus the need to check.
      var isDropTarget = (ui.sender === null);

      if (isDropTarget) {
        ui.item.data('this').saveDragResult();
      }
    },

    dragStart: function (e, ui) {
      ui.item.addClass("dragging");
    },

    dragStop: function (e, ui) {
      ui.item.removeClass("dragging");
    },

    handleAddNewImpedimentClick: function (e) {
      var row = $(this).parents("tr").first();
      $('#taskboard').data('this').newImpediment(row);
    },

    handleAddNewTaskClick: function (e) {
      var row = $(this).parents("tr").first();
      $('#taskboard').data('this').newTask(row);
    },

    loadColWidthPreference: function () {
      var w = RB.UserPreferences.get('taskboardColWidth');
      if (w === null || w === undefined) {
        w = this.defaultColWidth;
        RB.UserPreferences.set('taskboardColWidth', w);
      }
      $("#col_width input").val(w);
    },

    newImpediment: function (row) {
      var impediment, o;

      impediment = $('#impediment_template').children().first().clone();
      row.find(".list").first().prepend(impediment);

      o = RB.Factory.initialize(RB.Impediment, impediment);
      o.edit();
    },

    newTask: function (row) {
      var task, o;

      task = $('#task_template').children().first().clone();
      row.find(".list").first().prepend(task);

      o = RB.Factory.initialize(RB.Task, task);
      o.edit();
    },

    updateColWidths: function () {
      var w = parseInt($("#col_width input").val(), 10);

      if (isNaN(w) || w <= 0) {
        w = this.defaultColWidth;
      }
      $("#col_width input").val(w);
      RB.UserPreferences.set('taskboardColWidth', w);
      $(".swimlane").width(this.colWidthUnit * w).css('min-width', this.colWidthUnit * w);
    }
  });
}(jQuery));
