/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

/**************************************
  STORY
***************************************/
RB.Story = (function ($) {
  return RB.Object.create(RB.Issue, RB.EditableInplace, {
    initialize: function (el) {
      this.$ = $(el);
      this.el = el;

      // Associate this object with the element for later retrieval
      this.$.data('this', this);
      this.$.find(".editable").live('mouseup', this.handleClick);
    },

    /**
     * Callbacks from model.js
     **/
    beforeSave: function () {
      this.refresh();
    },

    afterCreate: function (data, textStatus, xhr) {
      this.refresh();
    },

    afterUpdate : function (data, textStatus, xhr) {
      this.refresh();
    },

    refreshed: function () {
      this.refresh();
    },
    /**/

    editDialogTitle: function () {
      return "Story #" + this.getID();
    },

    editorDisplayed: function (editor) {
      // editor.dialog("option", "position", "center");
    },

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

    refresh : function () {
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

      if (this.isNew()) {
        url = RB.urlFor('create_story');
      } else {
        url = RB.urlFor('update_story', {id: this.getID()});
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
