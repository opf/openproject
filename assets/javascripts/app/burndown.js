RB.Burndown = (function ($) {
  return RB.Object.create({

    initialize: function (el) {
      this.$ = $(el);
      this.el = el;

      // Associate this object with the element for later retrieval
      this.$.data('this', this);

      // Observe menu items
      this.$.click(this.show);
    },

    setSprintId : function (sprintId) {
      this.sprintId = sprintId;
    },

    getSprintId : function (){
      return this.sprintId;
    },

    show: function (e) {
      e.preventDefault();

      if ($("#charts").length === 0) {
        $('<div id="charts"></div>').appendTo("body");
      }
      $('#charts').html("<div class='loading'>" + RB.i18n.generating_graph + "</div>");
      $('#charts').load(RB.urlFor('show_burndown_chart', { id: $(this).data('this').sprintId,
                                                           project_id: RB.constants.project_id}));
      $('#charts').dialog({
        dialogClass: "rb_dialog",
        height: 530,
        width: 710,
        position: 'center',
        modal: true,
        title: RB.i18n.burndown_graph,
        resizable: false
      });
    }
  });
}(jQuery));
