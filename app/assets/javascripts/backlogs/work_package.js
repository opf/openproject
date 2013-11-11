/**************************************
  WORK PACKAGE
***************************************/
RB.WorkPackage = (function ($) {
  return RB.Object.create(RB.Model, {

    initialize: function (el) {
      this.$ = $(el);
      this.el = el;
    },

    beforeSaveDragResult: function () {
      // Do nothing
    },

    getType: function () {
      return "WorkPackage";
    },

    saveDragResult: function () {
      this.beforeSaveDragResult();
      if (!this.$.hasClass('editing')) {
        this.saveEdits();
      }
    }
  });
}(jQuery));
