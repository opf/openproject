window.backbone_app.views.PlanningElementsView = window.backbone_app.views.BaseView.extend({
  tagName: "div",

  className: "backbone-app",

  events: {},

  parent: function(){
    return this.options.parent;
  },

  initialize: function(){
    this.collection.bind("reset", _.bind(this.render, this));
    this.collection.fetch({
      reset: true
    }); // Note: We won't want to reset on fetch, we should listen for add/remove/change
  },

  render: function(){
    console.log('rendering planning elements');
    // TODO RS: Make templates and work through all the terrifying ui code
    // To begin with should or might even have to just stick with the original code to
    // fill up the svg element.

    // Try to use old Timeline code with backbone models
    var lib_timelines = this.options.lib_timelines;
    var tree = lib_timelines.getLefthandTreeBackbone(this.parent(), this.collection);
    var ui_root = jQuery('.tl-chart');
    lib_timelines.completeUIBackbone(tree, ui_root);
    lib_timelines.rebuildGraphBackbone(tree, ui_root);
  }
});