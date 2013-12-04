window.backbone_app.views.PlanningElementTimelineView = window.backbone_app.views.BaseView.extend({
  tagName: "div",

  className: "planning-element",

  events: {},

  parent: function(){
    return this.options.parent;
  },

  initialize: function(){
    // We require here the timeline, the raphael drawing element and options
  },

  render: function(){
    console.log('rendering planning element');
    // TODO RS: Draw element a la PlanningElement:render()
  }
});