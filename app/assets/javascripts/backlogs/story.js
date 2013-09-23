/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

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
      this.$.find(".editable").live('mouseup', this.handleClick);
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

//TODO: this might be unsave in case the parent of this story is not the sprint backlog, then we dont have
//a sprintId an cannot generate a valid url - one option might be to take RB.constants.sprint_id hoping it exists
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
