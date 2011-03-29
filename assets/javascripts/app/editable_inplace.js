/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

RB.EditableInplace = (function ($) {
  return RB.Object.create(RB.Model, {

    displayEditor: function (editor) {
      this.$.addClass("editing");
      editor.find(".editor").bind('keyup', this.handleKeyup);
    },

    getEditor: function () {
      // Create the model editor if it does not yet exist
      //
      // TODO: Review usage of editor and editor.length
      var editor = this.$.children(".editors").first();

      if (editor.length === 0) {
        editor = $("<div class='editors'></div>").appendTo(this.$);
      }
      return editor;
    },

    handleKeyup: function (e) {
      var j, that;

      j = $(this).parents('.model').first();
      that = j.data('this');

      switch (e.which) {
      case 13: // Enter
        that.saveEdits();
        break;
      case 27: // ESC
        that.cancelEdit();
        break;
      default:
        return true;
      }
    }
  });
}(jQuery));
