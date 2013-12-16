window.backbone_app.views.TimelineView = window.backbone_app.views.BaseView.extend({
  tagName: "div",

  className: "backbone-app",

  template: function(){
    return _.template(jQuery('#timeline-container-template').html(), {model: this.project()});
  },

  /* Note to team:
    Just now i've only done project expand but we'd need the outline dropdown and zoom events too.
  */
  events : {
    "change #zoom-select" : "handleZoomChange",
    "click .project-expand" : "handleProjectExpand",
  },

  initialize: function(){
    this.collection.bind("reset", _.bind(this.render, this));
    this.collection.fetch({
      reset: true,
      data: {ids: this.options.project_id}
    }); // Note: We won't want to reset on fetch, we should listen for add/remove/change
    // this.expanded = false;
  },

  /* This is a temp hack because I'm just trying to get all this working with one project */
  project: function(){
    return this.collection.first();
  },

  render: function(){
    console.log('rendering project');
    this.$el.html(this.template());
    this.renderSubViews();
    this.initComponents();
  },

  renderSubViews: function(){
    this.initPlanningElementsView();
    // reportings, statuses, planning_element_types, colors, project_types...
  },

  initPlanningElementsView: function(){
    var planning_elements = new backbone_app.collections.PlanningElements([],
      {project_id: this.options.project_id});
    this.planning_elements_view = new backbone_app.views.PlanningElementsView({
      el: jQuery(".tl-project-row[data-project-identifier='" + this.options.project_id + "']"),
      collection: planning_elements,
      project_id: this.options.project_id,
      parent: this.project(),
      lib_timelines: this.options.lib_timelines
    });
  },

  /* Set up the behaviour of the timeline form components that need extra init
     eg. jquery components. */
  initComponents: function(){
    var self = this;

    var zooms = jQuery('#zoom-select');
    for (i = 0; i < Timeline.ZOOM_SCALES.length; i++) {
      zooms.append(jQuery(
        '<option>' +
        self.i18n(Timeline.ZOOM_CONFIGURATIONS[Timeline.ZOOM_SCALES[i]].name) +
        '</option>'));
    }

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

  handleProjectExpand: function(e){
    var target = jQuery(e.target);
    console.log("expand" + target.data('project-identifier'));
    this.planning_elements_view.expandProject(target.parent());
    return false;
  },

  /* UI Methods */
  zoom: function(index){
    // TODO RS: Implement this
    console.log('Zoooooom!');
  },

  // requireChartRebuild: function(){
  //   this.planning_elements_view.renderChart({expanded: this.expanded});
  // }

});