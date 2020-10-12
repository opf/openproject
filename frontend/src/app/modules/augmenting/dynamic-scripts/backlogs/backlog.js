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

/******************************************
  BACKLOG
  A backlog is a visual representation of
  a sprint and its stories. It is not a
  sprint. Imagine it this way: A sprint is
  a start and end date, and a set of
  objectives. A backlog is something you
  would draw up on the board or a spread-
  sheet (or in Redmine Backlogs!) to
  visualize the sprint.
******************************************/

RB.Backlog = (function ($) {
  return RB.Object.create({

    initialize: function (el) {
      this.$ = $(el);
      this.el = el;

      // Associate this object with the element for later retrieval
      this.$.data('this', this);

      // Make the list sortable
      this.getList().sortable({
        connectWith: '.stories',
        dropOnEmpty: true,
        start:   this.dragStart,
        stop:    this.dragStop,
        update:  this.dragComplete,
        receive: this.dragChanged,
        remove:  this.dragChanged,
        containment: $('#backlogs_container'),
        scroll: true,
        helper: function(event, ui){
          var $clone =  $(ui).clone();
          $clone .css('position','absolute');
          return $clone.get(0);
        }
      });

      // Observe menu items
      this.$.find('.add_new_story').click(this.handleNewStoryClick);

      if (this.isSprintBacklog()) {
        RB.Factory.initialize(RB.Sprint, this.getSprint());
        this.burndown = RB.Factory.initialize(RB.Burndown, this.$.find('.show_burndown_chart'));
        this.burndown.setSprintId(this.getSprint().data('this').getID());
      }

      // Initialize each item in the backlog
      this.getStories().each(function (index) {
        // 'this' refers to an element with class="story"
        RB.Factory.initialize(RB.Story, this);
      });

      if (this.isSprintBacklog()) {
        this.refresh();
      }
    },

    dragChanged: function (e, ui) {
      $(this).parents('.backlog').data('this').refresh();
    },

    dragComplete: function (e, ui) {
      var isDropTarget = (ui.sender === null || ui.sender === undefined);

      // jQuery triggers dragComplete of source and target.
      // Thus we have to check here. Otherwise, the story
      // would be saved twice.
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

    getSprint: function () {
      return $(this.el).find(".model.sprint").first();
    },

    getStories: function () {
      return this.getList().children(".story");
    },

    getList: function () {
      return this.$.children(".stories").first();
    },

    handleNewStoryClick: function (e) {
      var toggler = $(this).parents('.header').find('.toggler');
      if (toggler.hasClass('closed')){
        toggler.click();
      }
      e.preventDefault();
      $(this).parents('.backlog').data('this').newStory();
    },

    // return true if backlog has an element with class="sprint"
    isSprintBacklog: function () {
      return $(this.el).find('.sprint').length === 1;
    },

    newStory: function () {
      var story, o;

      story = $('#story_template').children().first().clone();
      this.getList().prepend(story);

      o = RB.Factory.initialize(RB.Story, story[0]);
      o.edit();

      story.find('.editor').first().focus();
    },

    refresh : function () {
      this.recalcVelocity();
      this.recalcOddity();
    },

    recalcVelocity: function () {
      var total;

      if (!this.isSprintBacklog()) {
        return true;
      }

      total = 0;
      this.getStories().each(function (index) {
        total += $(this).data('this').getPoints();
      });
      this.$.children('.header').children('.velocity').text(total);
    },

    recalcOddity : function () {
      this.$.find('.story:even').removeClass('odd').addClass('even');
      this.$.find('.story:odd').removeClass('even').addClass('odd');
    }
  });
}(jQuery));
