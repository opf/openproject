window.backbone_app = {
  models: {},
  collections: {},
  views: {}
};

if (typeof TimelineBackboneApp === "undefined") {
  TimelineBackboneApp = {};
}

// Set underscore templates to parse things like this:
// {{ value }}
// because currently using erb templates which interfere with <% value %>.
// I think we should use Handlebars or something else so we can remove this
// once we've switched away from underscore.
_.templateSettings = {
  interpolate: /\{\{\=(.+?)\}\}/g,
  evaluate: /\{\{(.+?)\}\}/g
};

jQuery.extend(TimelineBackboneApp, {
  init: function(options, lib_timelines){
    var opt = options; // TODO RS: Boil options down to the useful bits
    var projects = new backbone_app.collections.Projects;
    var project_view = new backbone_app.views.TimelineView({
      collection: projects,
      project_id: opt.project_id,
      el: opt.ui_root,
      i18n: opt.i18n,
      lib_timelines: lib_timelines
    });
  },
});