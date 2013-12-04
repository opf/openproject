window.backbone_app.models.Project = Backbone.Model.extend({

  /* Methods required by TreeNode when rendering and generally for the current setup.
     Once I've got comfortable with how things work I'll start messing it up:D */
  identifier: 'projects',

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
  },
});