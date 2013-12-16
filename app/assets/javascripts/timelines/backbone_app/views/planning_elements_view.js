window.backbone_app.views.PlanningElementsView = window.backbone_app.views.BaseView.extend({

  className: "backbone-app",

  /* Note to team:
    In this view I would like to setup backbone event handlers for actions that can be
    done on planning elements. However given that currently the actual planning
    element html elements are not attached to the DOM (they're only on the node tree, is
    that correct?) I'm not sure that it would work.

    If this is the case then I think this would be a good area to think about so
    that we can get lots of nice event handlers in here for all the actions that could
    be performed on planning elements on the graph.
  */
  events: {},

  template: function(){
    return _.template(jQuery('#planning-element-headers-template').html(),
      {
        collection: this.collection,
        parent_id: this.options.parent.get('identifier')
      });
  },

  parent: function(){
    return this.options.parent;
  },

  initialize: function(){
    this.collection.bind("reset", _.bind(this.render, this));
    this.collection.fetch({
      reset: true
    }); // Note: We won't want to reset on fetch, we should listen for add/remove/change
    this.expanded = false;
  },

  render: function(){
    console.log('rendering all planning elements');
    // Note: Remeber we are inserting table rows after the project row. Not so nice but that's
    //       how it's done right now.
    this.$el.nextAll().remove();
    this.$el.after(this.template());

    this.renderChart({expanded: false});
  },

  expandProject: function(td){
    // var td = project_link.parent();
    if(this.expanded){
      td.removeClass('tl-expanded')
      td.addClass('tl-collapsed')
      jQuery("tr[data-parent-project=" + this.options.parent.get('identifier') + "]").hide();
    } else {
      td.removeClass('tl-collapsed')
      td.addClass('tl-expanded')
      jQuery("tr[data-parent-project=" + this.options.parent.get('identifier') + "]").show();
    }
    this.expanded = !this.expanded;
    this.renderChart({expanded: this.expanded});

    return false;
  },

  renderExpanded: function(){
    this.$el.nextAll().remove();
    this.$el.after(this.template());
    var td = jQuery("[data-cell-project-identifier=" + this.options.parent.get('identifier') + "]")
    this.expandProject(td);
  },

  renderChart: function(options){
    var lib_timelines = this.options.lib_timelines;
    var tree = lib_timelines.getLefthandTreeBackbone(this.parent(), this.collection);
    var ui_root = jQuery('.tl-chart');
    lib_timelines.completeUIBackbone(tree, ui_root);
    lib_timelines.setTreeDomElements(tree);
    lib_timelines.adjustForPlanningElementsBackbone(this.options.parent, this.collection);
    lib_timelines.rebuildGraphBackground(tree, ui_root);

    // Render the first project
    // ALERT: Only for demonstration!
    // This is a hack to try and just get one project displaying!
    var project_node = tree

    // ALERT: Here we are creating and rendering one project timeline view but really there
    // should be one for each of the projects in the tree.
    var project_timeline_view = new window.backbone_app.views.ProjectTimelineView({
      parent_view: this,
      timeline: lib_timelines,
      paper: lib_timelines.paper,
      node: project_node,
      expanded: options.expanded,
    });
    project_timeline_view.render();
  },

  redrawRequired: function(){
    this.renderExpanded();
  }

});