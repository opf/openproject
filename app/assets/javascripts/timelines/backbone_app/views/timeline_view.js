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
    this.expanded = false;
  },

  /* This is a temp hack because I'm just trying to get all this working with one project */
  project: function(){
    return this.collection.first();
  },

  render: function(){
    console.log('rendering project');
    // TODO RS: Might want to split up this template into the toolbar and svg container
    this.$el.html(this.template());
    this.renderSubViews();
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

  handleProjectExpand: function(e){
    var target = jQuery(e.target);
    console.log("expand" + target.data('project-identifier'));

    var td = target.parent();
    if(this.expanded){
      td.removeClass('tl-expanded')
      td.addClass('tl-collapsed')
      jQuery("tr[data-parent-project=" + this.project().get('identifier') + "]").hide();
    } else {
      td.removeClass('tl-collapsed')
      td.addClass('tl-expanded')
      jQuery("tr[data-parent-project=" + this.project().get('identifier') + "]").show();
    }
    this.expanded = !this.expanded;

    // TODO RS:
    // This requires a rebuild of the graph because the left column might have been resized.
    // Would be nice to set a rebuild flag and then have that picked up somewhere else.
    return false;
  },

  /* UI Methods */
  zoom: function(index){
    // TODO RS: Implement this
    console.log('Zoooooom!');
  },

});