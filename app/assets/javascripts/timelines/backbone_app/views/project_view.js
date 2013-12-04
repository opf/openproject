window.backbone_app.views.ProjectView = window.backbone_app.views.BaseView.extend({
  tagName: "div",

  className: "backbone-app",

  // el: function(){
  //   return this.options.ui_root;
  // }

  template: function(){
    return _.template(jQuery('#project-timeline-template').html(), {model: this.project()});
  },

  // Note: Just now i've only done zoom change but we'd need the outline dropdown events too
  events : {
    "change #zoom-select" : "handleZoomChange"
  },

  initialize: function(){
    this.collection.bind("reset", _.bind(this.render, this));
    this.collection.fetch({
      reset: true,
      data: {ids: this.options.project_id}
    }); // Note: We won't want to reset on fetch, we should listen for add/remove/change
  },

  /* This is a temp hack because I'm just trying to get all this working with one project */
  project: function(){
    return this.collection.first();
  },

  render: function(){
    console.log('rendering project');
    this.renderSubViews();
    // TODO RS: Might want to split up this template into the toolbar and svg container
    this.$el.html(this.template());
    this.initComponents();
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
      project_id: this.options.project_id,
      parent: this.project(),
      lib_timelines: this.options.lib_timelines
    });
  },

  /* Set up the behaviour of the timeline form components */
  /* Just now I've only done zoom but you get the idea */
  initComponents: function(){
    var self = this;

    // Zoom select
    // From: ui.js:491
    var zooms = jQuery('#zoom-select');
    for (i = 0; i < Timeline.ZOOM_SCALES.length; i++) {
      zooms.append(jQuery(
        '<option>' +
        self.i18n(Timeline.ZOOM_CONFIGURATIONS[Timeline.ZOOM_SCALES[i]].name) +
        '</option>'));
    }

    // From: ui.js:507
    // Note: The slider events 'slide' and 'change' can't be handled as backbone view events
    jQuery('#zoom-slider').slider({
      min: 1,
      max: Timeline.ZOOM_SCALES.length,
      range: 'min',
      value: zooms[0].selectedIndex + 1,
      slide: function(event, ui) {
        zooms[0].selectedIndex = ui.value - 1;
      },
      change: function(event, ui) {
        zooms[0].selectedIndex = ui.value - 1;
        self.zoom(ui.value - 1);
      }
    }).css({
      // top right bottom left
      'margin': '4px 6px 3px'
    });
  },

  /* Event Handlers */
  handleZoomChange: function(e){
    var slider = jQuery('#zoom-slider');
    slider.slider('value', jQuery(e.target).find(':selected').index());
  },

  /* UI Methods */
  zoom: function(index){
    // TODO RS: Implement this
    console.log('Zoooooom!');
  },
});