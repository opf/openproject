window.backbone_app.collections.Projects = Backbone.Collection.extend({
  url: "/api/v2/projects",

  model: function(attrs, options){
    return new window.backbone_app.models.Project(attrs, options);
  },

  parse: function(data){
    return data.projects;
  }
});