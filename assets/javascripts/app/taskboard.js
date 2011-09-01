/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

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
    },

    initializeNewButtons : function () {
      this.$.find('#tasks .add_new').click(this.handleAddNewTaskClick);
      this.$.find('#impediments .add_new').click(this.handleAddNewImpedimentClick);
    },

    initializeSortables : function () {
      this.$.find('#impediments .list').sortable({
        placeholder: 'placeholder',
        start:  this.dragStart,
        stop:   this.dragStop,
        update: this.dragComplete
      }).sortable('option', 'connectWith', '#impediments .list');

      var list, augmentList, self = this;

      list = this.$.find('#tasks .list');

      augmentList = function () {
        $(list.splice(0, 50)).sortable({
          placeholder: 'placeholder',
          start:  self.dragStart,
          stop:   self.dragStop,
          update: self.dragComplete
        }).sortable('option', 'connectWith', '#tasks .list');

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

      // FIXME: workaround for IE7
      if ($.browser.msie && $.browser.version <= 7) {
        ui.item.css("z-index", 0);
      }
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

      if (w === null || w === undefined || isNaN(w)) {
        w = this.defaultColWidth;
      }
      $("#col_width input").val(w);
      RB.UserPreferences.set('taskboardColWidth', w);
      $(".swimlane").width(this.colWidthUnit * w).css('min-width', this.colWidthUnit * w);
    }
  });
}(jQuery));
