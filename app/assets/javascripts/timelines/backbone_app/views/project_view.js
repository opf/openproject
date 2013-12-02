window.backbone_app.views.ProjectView = Backbone.View.extend({
  tagName: "div",

  className: "backbone-app",

  events: {},

  initialize: function(){
    this.collection.bind("reset", _.bind(this.render, this));
    this.collection.fetch({
      reset: true,
      data: {ids: this.options.project_id}
    }); // Note: We won't want to reset on fetch, we should listen for add/remove/change
  },

  render: function(){
    console.log('rendering');
  }
});