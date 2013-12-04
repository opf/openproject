window.backbone_app.models.PlanningElement = Backbone.Model.extend({
  // TODO RS: Look into if this is possible/sensible ie are sub-elements
  // returned in the server response json?
  getSubElements: function(){
    return [];
  },

  /* Methods required by TreeNode when rendering and generally for the current setup.
     Once I've got comfortable with how things work I'll start messing it up:D */
  identifier: 'planning_elements',

  is: function(t) {
    return this.identifier === t.identifier;
  },

  /* TODO RS: If these cannot be determined by what is returned from the
     server then we're going to have to set a flag on the model from the
     view somehow. */
  filteredOut: function(){
    return false;
  },

  hide: function(){
    return false;
  }
});