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

    // Try to use old Timeline code with backbone models
    var lib_timelines = this.options.lib_timelines;
    var tree = lib_timelines.getLefthandTreeBackbone(this.parent(), this.collection);
    var ui_root = jQuery('.tl-chart');
    lib_timelines.completeUIBackbone(tree, ui_root);

    // Draw the chart background and get a list of renderable planning elements
    // TODO RS: Still using lib_timelines as a buffer but really we want to move everything
    // to the views so have a drawBackground() method and also call getRenderableElementNodes()
    // separately and see if we could remove it altogether.

    // TODO RS: This is a more generalised solution but right now i just want to get it
    // working for one project

    // var planning_element_nodes = lib_timelines.rebuildGraphBackbone(tree, ui_root);
    // jQuery.each(planning_element_nodes, function(i, node){
    //   console.log("init planning element" + node.payload.get('description'));
    //   var pe_view = new window.backbone_app.views.PlanningElementTimelineView({
    //     timeline: lib_timelines,
    //     paper: ui_root,
    //     node: node,
    //     in_aggregation: false, // TODO RS: What's this for?
    //     label_space: false // TODO RS: What's this for?
    //   });
    //   pe_view.render();
    // })

    // Render the first project
    // ALERT: Only for demonstration!
    // This is a hack to try and just get one project displaying!
    lib_timelines.rebuildGraphBackground(tree, ui_root);
    var project_node = tree

    // Get a list of planning element models
    // ALERT: Only for demonstration!
    // Again this is assuming that we only have planning elements and will of
    // course need to be extended for other things.
    var planning_element_nodes = project_node.childNodes;
    var planning_elements = [];
    jQuery.each(planning_element_nodes, function(i, node){
      planning_elements.push(node.payload);
    })

    var project_timeline_view = new window.backbone_app.views.ProjectTimelineView({
      timeline: lib_timelines,
      paper: ui_root,
      node: project_node,
      planning_elements: planning_elements,
    });
    project_timeline_view.render();
  }
});