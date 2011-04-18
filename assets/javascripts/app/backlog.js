/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

/******************************************
  BACKLOG
  A backlog is a visual representation of
  a sprint and its stories. It's is not a
  sprint. Imagine it this way: a sprint is
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
        placeholder: 'placeholder',
        forcePlaceholderSize: true,
        dropOnEmpty: true,
        start:   this.dragStart,
        stop:    this.dragStop,
        update:  this.dragComplete,
        receive: this.dragChanged,
        remove:  this.dragChanged
      });

      // Observe menu items
      this.$.find('.add_new_story').click(this.handleNewStoryClick);
      this.$.find('.show_burndown_chart').click(this.showBurndownChart);

      if (this.isSprintBacklog()) {
        RB.Factory.initialize(RB.Sprint, this.getSprint());
      }

      // Initialize each item in the backlog
      this.getStories().each(function (index) {
        // 'this' refers to an element with class="story"
        RB.Factory.initialize(RB.Story, this);
      });

      if (this.isSprintBacklog()) {
        this.recalcVelocity();
      }
    },

    dragChanged: function (e, ui) {
      $(this).parents('.backlog').data('this').recalcVelocity();
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

    showBurndownChart: function (e) {
      var backlogs;

      e.preventDefault();

      backlogs = $(this).parents('.backlog').data('this');

      if ($("#charts").length === 0) {
        $('<div id="charts"></div>').appendTo("body");
      }
      $('#charts').html("<div class='loading'>" + RB.i18n['generating_graph'] + "</div>");
      $('#charts').load(RB.urlFor('show_burndown_chart', { id: backlogs.getSprint().data('this').getID(),
                                                           project_id: RB.constants['project_id']}));
      $('#charts').dialog({
        buttons: [{
          text: RB.i18n['close'],
          click: function() { $(this).dialog("close"); }
        }],
        dialogClass: "rb_dialog",
        height: 500,
        position: 'center',
        modal: true,
        title: RB.i18n['burndown_graph'],
        width: 710
      });
    }
  });
}(jQuery));
