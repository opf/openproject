/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

/**************************************
  TASK
***************************************/

RB.Task = (function ($) {
  return RB.Object.create(RB.Issue, {

    initialize: function (el) {
      this.$ = $(el);
      this.el = el;

      // If node is based on #task_template, it doesn't have the story class yet
      this.$.addClass("task");

      // Associate this object with the element for later retrieval
      this.$.data('this', this);
      this.$.find(".editable").live('click', this.handleClick);
    },

    beforeSave: function () {
      var c = this.$.find('select.assigned_to_id').children(':selected').attr('color');
      this.$.css('background-color', c);
    },

    editorDisplayed: function (dialog) {
      dialog.parents('.ui-dialog').css('background-color', this.$.css('background-color'));
    },

    getType: function () {
      return "Task";
    },

    markIfClosed: function () {
      if (this.$.parent('td').first().hasClass('closed')) {
        this.$.addClass('closed');
      } else {
        this.$.removeClass('closed');
      }
    },

    saveDirectives: function () {
      var prev, cellId, data, url;

      prev = this.$.prev();
      cellId = this.$.parent('td').first().attr('id').split("_");

      data = this.$.find('.editor').serialize() +
                 "&parent_issue_id=" + cellId[0] +
                 "&status_id=" + cellId[1] +
                 "&prev=" + (prev.length === 1 ? prev.data('this').getID() : '') +
                 (this.isNew() ? "" : "&id=" + this.$.children('.id').text());

      if (this.isNew()) {
        url = RB.urlFor('create_task');
      }
      else {
        url = RB.urlFor('update_task', {id: this.getID()});
        data += "&_method=put";
      }

      return {
        url: url,
        data: data
      };
    },

    beforeSaveDragResult: function () {
      if (this.$.parent('td').first().hasClass('closed')) {
        // This is only for the purpose of making the Remaining Hours reset
        // instantaneously after dragging to a closed status. The server should
        // still make sure to reset the value to be sure.
        this.$.children('.remaining_hours.editor').val('');
        this.$.children('.remaining_hours.editable').text('');
      }
    },

    refreshed : function () {
      var remainingHours = this.$.children('.remaining_hours.editable');

      remainingHours.toggleClass('empty', remainingHours.is(':empty'));
    }
  });
}(jQuery));
