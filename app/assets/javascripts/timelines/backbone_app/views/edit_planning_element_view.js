window.backbone_app.views.EditPlanningElementView = window.backbone_app.views.BaseView.extend({
  tagName: "div",

  className: "edit-planning-element",

  events: {
    "submit #edit-planning-element-form": "updatePlanningElement",
  },

  template: function(){
    return _.template(jQuery('#edit-planning-element-template').html(),
      {
        model: this.model,
        options: this.options,
      });
  },

  initialize: function(model, options){
    this.model = model;
    this.options = options;
  },

  render: function(){
    var edit_view = this.template();
    this.$el.html(edit_view)
    jQuery('body').append(this.$el);
    return edit_view;
  },

  removeEditForm: function(){
    jQuery('.edit-pe').remove();
  },

  updatePlanningElement: function(e){
    console.log('update');
    // TODO RS: What's the shorthand for this again?
    var subject = this.$el.find('input[name=subject]').val();
    this.model.set({
      subject: subject,
    });
    this.model.save();
    this.removeEditForm();

    return false;
  },
});