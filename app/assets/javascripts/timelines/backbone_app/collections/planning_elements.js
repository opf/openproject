window.backbone_app.collections.PlanningElements = Backbone.Collection.extend({
  initialize: function(models, options){
    this.options = options;
  },

  url: function(){
    return "/api/v2/projects/" + this.options.project_id + "/planning_elements";
  },

  model: function(attrs, options){
    return new window.backbone_app.models.PlanningElement(attrs, options);
  },

  parse: function(data){
    return data.planning_elements;
  }
});