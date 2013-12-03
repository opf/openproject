window.backbone_app = {
  models: {},
  collections: {},
  views: {}
};

if (typeof TimelineBackboneApp === "undefined") {
  TimelineBackboneApp = {};
}

jQuery.extend(TimelineBackboneApp, {
  init: function(options){
    var opt = options; // TODO RS: Boil options down to the useful bits
    var projects = new backbone_app.collections.Projects;
    var project_view = new backbone_app.views.ProjectView({
      collection: projects,
      project_id: opt.project_id,
      el: opt.ui_root
    });
  },
});