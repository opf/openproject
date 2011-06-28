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

      // FIXME: workaround for IE7
      if ($.browser.msie && $.browser.version <= 7) {
        ui.item.css("z-index", 0);
      }
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
