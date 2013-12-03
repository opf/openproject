window.backbone_app.views.ProjectView = Backbone.View.extend({
  tagName: "div",

  className: "backbone-app",

  // el: function(){
  //   return this.options.ui_root;
  // }

  template: function(){
    return _.template(jQuery('#project-timeline-template').html(), {projects: this.collection})
  },

  events: {},

  initialize: function(){
    this.collection.bind("reset", _.bind(this.render, this));
    this.collection.fetch({
      reset: true,
      data: {ids: this.options.project_id}
    }); // Note: We won't want to reset on fetch, we should listen for add/remove/change
  },

  render: function(){
    console.log('rendering project');
    this.renderSubViews();
    // TODO RS: Might want to split up this template into the toolbar and svg container
    this.$el.html(this.template());
  },

  renderSubViews: function(){
    // Note: Not sure if we have to wait until projects view has rendered before we render the
    //       sub views so maybe this should be called from initialize instead of render.

    this.initPlanningElementsView();
    // reportings, statuses, planning_element_types, colors, project_types...
  },

  initPlanningElementsView: function(){
    var planning_elements = new backbone_app.collections.PlanningElements([],
      {project_id: this.options.project_id});
    var planning_elements_view = new backbone_app.views.PlanningElementsView({
      collection: planning_elements,
      project_id: this.options.project_id
    });
  }
});