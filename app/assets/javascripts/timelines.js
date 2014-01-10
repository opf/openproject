//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

// ╭───────────────────────────────────────────────────────────────╮
// │  _____ _                _ _                                   │
// │ |_   _(_)_ __ ___   ___| (_)_ __   ___  ___                   │
// │   | | | | '_ ` _ \ / _ \ | | '_ \ / _ \/ __|                  │
// │   | | | | | | | | |  __/ | | | | |  __/\__ \                  │
// │   |_| |_|_| |_| |_|\___|_|_|_| |_|\___||___/                  │
// ├───────────────────────────────────────────────────────────────┤
// │ Javascript library that fetches and plots timelines for the   │
// │ OpenProject timelines module.                                 │
// ╰───────────────────────────────────────────────────────────────╯

//= require timelines/FilterQueryStringBuilder
//= require timelines/TimelineLoader

//= require timelines/TreeNode

//= require timelines/constants
//= require timelines/ui


//= require timelines/model/Project
//= require timelines/model/PlanningElement
//= require timelines/model/HistoricalPlanningElement

//= require timelines/model/ProjectAssociation
//= require timelines/model/Reporting
//= require timelines/model/ProjectType
//= require timelines/model/Color
//= require timelines/model/Status
//= require timelines/model/PlanningElementType
//= require timelines/model/User


// stricter than default
/*jshint undef:true,
         eqeqeq:true,
         forin:true,
         immed:true,
         latedef:true,
         trailing: true
*/

// looser than default
/*jshint eqnull:true */

// environment and other global vars
/*jshint browser:true, devel:true*/
/*global jQuery:false, Raphael:false, Timeline:true*/

if (typeof Timeline === "undefined") {
  Timeline = {};
}

//startup
jQuery.extend(Timeline, {
  instances: [],
  get: function(n) {
    if (typeof n !== "number") {
      n = 0;
    }
    return this.instances[n];
  },
  isInstance: function(n) {
    return (n === undefined) ?
      Timeline.instances.indexOf(this) :
      this === Timeline.get(n);
  },
  isGrouping: function() {
    if ((this.options.grouping_one_enabled === 'yes' &&
         this.options.grouping_one_selection !== undefined) ||
        (this.options.grouping_two_enabled === 'yes' &&
         this.options.grouping_two_selection !== undefined)) {
      return true;
    } else {
      return false;
    }
  },
  isComparing: function() {
    return ((this.options.comparison !== undefined) &&
            (this.options.comparison !== 'none'));
  },
  comparisonCurrentTime: function() {
    var value;
    if (!this.isComparing()) {
      return undefined;
    }
    if (this.options.comparison === 'historical') {
      value = this.options.compare_to_historical_two;
    }
    else {
      // default is no (undefined) current time, which corresponds to today.
      return undefined;
    }
    return +Date.parse(value) / 1000;
  },
  calculateTimeFilter: function () {
    if (!this.frameSet) {
      if (this.options.planning_element_time === "absolute") {
        this.frameStart = Date.parse(this.options.planning_element_time_absolute_one);
        this.frameEnd = Date.parse(this.options.planning_element_time_absolute_two);
      } else if (this.options.planning_element_time === "relative") {
        var startR = parseInt(this.options.planning_element_time_relative_one, 10);
        var endR = parseInt(this.options.planning_element_time_relative_two, 10);
        if (!isNaN(startR)) {
          this.frameStart = Date.now();

          switch (this.options.planning_element_time_relative_one_unit[0]) {
            case "0":
              this.frameStart.add(-1 * startR).days();
              break;
            case "1":
              this.frameStart.add(-1 * startR).weeks();
              break;
            case "2":
              this.frameStart.add(-1 * startR).months();
              break;
          }
        }

        if (!isNaN(endR)) {
          this.frameEnd = Date.now();

          switch (this.options.planning_element_time_relative_two_unit[0]) {
            case "0":
              this.frameEnd.add(endR).days();
              break;
            case "1":
              this.frameEnd.add(endR).weeks();
              break;
            case "2":
              this.frameEnd.add(endR).months();
              break;
          }
        }
      }

      this.frameSet = true;
    }
  },
  inTimeFilter: function (start, end) {
    this.calculateTimeFilter();

    if (!start && !end) {
      return false;
    }

    if (!start) {
      start = end;
    }

    if (!end) {
      end = start;
    }

    if (this.frameStart) {
      if (start < this.frameStart && end < this.frameStart) {
        return false;
      }
    }

    if (this.frameEnd) {
      if (start > this.frameEnd && end > this.frameEnd) {
        return false;
      }
    }

    return true;
  },
  verticalPlanningElementIds: function() {

    return this.options.vertical_planning_elements ?
      jQuery.map(
        this.options.vertical_planning_elements.split(/\,/),
        function(a) {
          try {
            return parseInt(a.match(/\s*\*?(\d*)\s*/)[1], 10);
          } catch (e) {
            return;
          }
        }
      ) : [];
  },
  comparisonTarget: function() {
    var result, value, unit;
    if (!this.isComparing()) {
      return undefined;
    }
    switch (this.options.comparison) {
      case 'relative':
        result = new Date();
        value = Timeline.pnum(this.options.compare_to_relative);
        unit = Timeline.pnum(this.options.compare_to_relative_unit[0]);
        switch (unit) {
          case 0:
            return Math.floor(result.add(-value).days() / 1000);
          case 1:
            return Math.floor(result.add(-value).weeks() / 1000);
          case 2:
            return Math.floor(result.add(-value).months() / 1000);
          default:
            return this.die(this.i18n('timelines.errors.report_comparison'));
        }
        break; // to please jslint
      case 'absolute':
        value = this.options.compare_to_absolute;
        break;
      case 'historical':
        value = this.options.compare_to_historical_one;
        break;
      default:
        return this.die(this.i18n('timelines.errors.report_comparison'));
    }
    return +Date.parse(value)/1000;
  },
  create: function() {
    var timeline = Object.create(Timeline);

    // some private fields.
    timeline.listeners = [];
    timeline.data = {};

    Timeline.instances.push(timeline);
    return timeline;
  },

  startup: function(options) {
    var timeline = this, timelineLoader;

    if(this === Timeline) {
      timeline = Timeline.create();
      return timeline.startup(options);
    }

    // configuration

    if (!options) {
      throw new Error('No configuration options given');
    }
    options = jQuery.extend({}, this.defaults, options);
    this.options = options;

    // we're hiding the root if there is a grouping.
    this.options.hide_tree_root = this.isGrouping();

    if (this.options.username) {
      this.ajax_defaults.username = this.options.username;
    }
    if (this.options.password) {
      this.ajax_defaults.password = this.options.password;
    }
    if (this.options.api_key) {
      this.ajax_defaults.headers = {
        'X-ChiliProject-API-Key': this.options.api_key,
        'X-OpenProject-API-Key':  this.options.api_key,
        'X-Redmine-API-Key':      this.options.api_key
      };
    }

    // setup UI.

    this.uiRoot = this.options.ui_root;
    this.setupUI();

    try {

      // prerequisites (3rd party libs)
      this.checkPrerequisites();
      this.modalHelper = modalHelperInstance;
      this.modalHelper.setupTimeline(
        this,
        {
          api_prefix                : this.options.api_prefix,
          url_prefix                : this.options.url_prefix,
          project_prefix            : this.options.project_prefix
        }
      );

      jQuery(this.modalHelper).on("closed", function () {
        timeline.reload();
      });

      timelineLoader = this.provideTimelineLoader();

      jQuery(timelineLoader).on('complete', jQuery.proxy(function(e, data) {
        jQuery.extend(this, data);

        jQuery(this).trigger('dataLoaded');
        this.defer(jQuery.proxy(this, 'onLoadComplete'),
                   this.options.artificial_load_delay);
      }, this));

      this.safetyHook = window.setTimeout(function() {
        timeline.die(timeline.i18n('timelines.errors.report_timeout'));
      }, Timeline.LOAD_ERROR_TIMEOUT);

      timelineLoader.load();

      return this;

    } catch (e) {
      this.die(e);
    }
  },
  checkPrerequisites: function() {
    if (jQuery === undefined) {
      throw new Error('jQuery seems to be missing (jQuery is undefined)');
    } else if (jQuery().slider === undefined) {
      throw new Error('jQuery UI seems to be missing (jQuery().slider is undefined)');
    } else if ((1).month === undefined) {
      throw new Error('date.js seems to be missing ((1).month is undefined)');
    } else if (Raphael === undefined) {
      throw new Error('Raphael seems to be missing (Raphael is undefined)');
    }
    return true;
  },
  reload: function() {
    delete this.lefthandTree;

    var timelineLoader = this.provideTimelineLoader();

    jQuery(timelineLoader).on('complete', jQuery.proxy(function (e, data) {

      jQuery.extend(this, data);
      jQuery(this).trigger('dataReLoaded');

      if (this.isGrouping() && this.options.grouping_two_enabled) {
        this.secondLevelGroupingAdjustments();
      }

      this.adjustForPlanningElements();

      this.rebuildAll();

    }, this));

    timelineLoader.load();
  },
  provideTimelineLoader: function() {
    return new Timeline.TimelineLoader(
      this,
      {
        api_prefix                    : this.options.api_prefix,
        url_prefix                    : this.options.url_prefix,
        project_prefix                : this.options.project_prefix,
        planning_element_prefix       : this.options.planning_element_prefix,
        project_id                    : this.options.project_id,
        project_types                 : this.options.project_types,
        project_statuses              : this.options.project_status,
        project_responsibles          : this.options.project_responsibles,
        project_parents               : this.options.parents,
        planning_element_types        : this.options.planning_element_types,
        planning_element_responsibles : this.options.planning_element_responsibles,
        planning_element_assignee     : this.options.planning_element_assignee,
        planning_element_status       : this.options.planning_element_status,
        grouping_one                  : (this.options.grouping_one_enabled ? this.options.grouping_one_selection : undefined),
        grouping_two                  : (this.options.grouping_two_enabled ? this.options.grouping_two_selection : undefined),
        ajax_defaults                 : this.ajax_defaults,
        current_time                  : this.comparisonCurrentTime(),
        target_time                   : this.comparisonTarget(),
        include_planning_elements     : this.verticalPlanningElementIds()
      }
    );
  },
  defer: function(action, delay) {
    var timeline = this;
    var result;
    if (delay === undefined) {
      delay = 0;
    }
    result = window.setTimeout(function() {
      try {
        action.call();
      } catch(e) {
        timeline.die(e);
      }
    }, 0);
    return result;
  },
  die: function(error, classes) {
    var message = (typeof error === 'string') ? error :
      this.i18n('timelines.errors.report_epicfail'); // + '<br>' + error.message;
    classes = classes || 'flash error';

    this.warn(message, classes);

    // assume this won't happen anymore.
    this.onLoadComplete = function() {};

    if (console && console.log) {
      console.log(error.stack);
    }

    throw error;
  },
  warn: function(message, classes) {
    var root = this.getUiRoot();

    window.setTimeout(function() {

      // generate and display the error message.
      var warning = jQuery('<div class="' + classes + '">' + message + '</div>');
      root.empty().append(warning);

    }, Timeline.DISPLAY_ERROR_DELAY);
  },
  onLoadComplete: function() {
    // everything here should be wrapped in try/catch, to never
    var tree;
    try {
      window.clearTimeout(this.safetyHook);

      if (this.isGrouping() && this.options.grouping_two_enabled) {
        this.secondLevelGroupingAdjustments();
      }

      tree = this.getLefthandTree();
      if (tree.containsPlanningElements() || tree.containsProjects()) {
        this.adjustForPlanningElements();
        this.completeUI();
      } else {
        this.warn(this.i18n('label_no_data'), 'warning');
      }
    } catch (e) {
      this.die(e);
    }
  },
  secondLevelGroupingAdjustments : function () {
    var grouping = jQuery.map(this.options.grouping_two_selection || [], Timeline.pnum);
    var root = this.getProject();
    var associations = Timeline.ProjectAssociation.all(this);
    var listToRemove = [];

    // for all projects on the first level
    jQuery.each(root.getReporters(), function (i, e) {

      // find all projects that are associated
      jQuery.each(associations, function (j, a) {

        if (a.involves(e)) {
          var other = a.getOther(e);
          if (typeof other.getProjectType === "function") {
            var pt = other.getProjectType();
            var type = pt !== null ? pt.id : -1;
            var relevant = false;

            jQuery.each(grouping, function(k, l) {
              if (l === type) {
                relevant = true;
              }
            });

            if (relevant) {

              // add the other project as a simulated reporter to the current one.
              e.addReporter(other);
              other.hasSecondLevelGroupingAdjustment = true;
              // remove the project from the root level of the report.
              listToRemove.push(other);

            }
          }
        }
      });
    });

    // remove all children of root that we couldn't remove while still iterating.
    jQuery.each(listToRemove, function(i, e) {
      root.removeReporter(e);
    });
  }
});

// ╭───────────────────────────────────────────────────────────────────╮
// │ Defaults and random accessors                                     │
// ╰───────────────────────────────────────────────────────────────────╯
jQuery.extend(Timeline, {
  // defines how many levels are expanded when a tree is created, zero
  // corresponds to the root being collapsed.
  firstDateSeen: null,
  lastDateSeen: null,

  getBeginning: function() {
    return (Date.parse(this.options.timeframe_start) ||
              (this.firstDateSeen && this.firstDateSeen.clone() ||
               new Date()).last().monday());
  },
  getEnd: function() {
    return (Date.parse(this.options.timeframe_end) ||
              (this.lastDateSeen && this.lastDateSeen.clone() ||
               new Date()).addWeeks(1).next().sunday());
  },
  getDaysBetween: function(a, b) {
    // some meat around date calculations that will be floored out again
    // later. this hopefully takes care of floating point imprecisions
    // and possible leap seconds, as we're only interested in days.
    var da = a - 1000 * 60 * 60 * 4;
    var db = b - 1000 * 60 * 60 * (-4);
    return Math.floor((db - da) / (1000 * 60 * 60 * 24));
  },
  includeDate: function(date) {
    if (date) {
      if (this.firstDateSeen == null ||
          date.compareTo(this.firstDateSeen) < 0) {
        this.firstDateSeen = date;
      } else if (this.lastDateSeen == null ||
                 date.compareTo(this.lastDateSeen) > 0) {
        this.lastDateSeen = date;
      }
    }
  },
  adjustForPlanningElements: function() {
    var timeline = this;
    var tree = this.getLefthandTree();

    // nullify potential previous dates seen. this is relevant when
    // adjusting after the addition of a planning element via modal.

    timeline.firstDateSeen = null;
    timeline.lastDateSeen = null;

    tree.iterateWithChildren(function(node) {
      var data = node.getData();
      if (data.is(Timeline.PlanningElement)) {
        timeline.includeDate(data.start());
        timeline.includeDate(data.end());
      }
    }, {
      traverseCollapsed: true
    });

  },
  getReportings: function() {
    return Timeline.Reporting.all(this);
  },
  getReporting: function(id) {
    return this.reportings[id];
  },
  getProjects: function() {
    return Timeline.Project.all(this);
  },
  getProject: function(id) {
    if (id === undefined) {
      return this.project;
    }
    else return this.projects[id];
  },
  getGroupForProject: function(p) {
    var i, j = 0, projects, key, group;
    var groups = this.getFirstLevelGroups();
    for (j = 0; j < groups.length; j += 1) {
      projects = groups[j].projects;
      group = this.getProject(groups[j].id);

      for (i = 0; i < projects.length; i++) {
        if (p.id === projects[i].id) {
          return {
            'id': group.id,
            'p': group,
            'number': j + 1,
            'name': group.name
          };
        }
      }
    }

    return {
      'number': 0,
      'id': 0,
      'name': this.i18n('timelines.filter.grouping_other')
    };
  },

  firstLevelGroups: undefined,
  getFirstLevelGroups: function() {
    if (this.firstLevelGroups !== undefined) {
      return this.firstLevelGroups;
    }
    var i, selection = this.options.grouping_one_selection;
    var p, groups = [], children;
    if (this.isGrouping()) {
      for ( i = 0; i < selection.length; i++ ) {
        p = this.getProject(selection[i]);
        if (p === undefined) {
          // projects may have subprojects that the current user knows
          // about, but which cannot be/ were not fetched in advance due
          // to lack of rights.
          continue;
        }
        children = this.getSubprojectsOf([selection[i]]);
        if (children.length !== 0) {
          groups.push({
            projects: children,
            id: selection[i]
          });
        }
      }
    }

    this.firstLevelGroups = groups;
    return groups;
  },
  getNumberOfGroups: function() {
    var result = this.options.hide_other_group? 0: 1;
    var groups = this.getFirstLevelGroups();
    return result + groups.length;
  },
  getSubprojectsOf: function(parents) {
    var projects = this.getProjects();
    var result = [];
    var timeline = this;

    // if parents is not an array, turn it into one with length 1, so
    // the following each does not fail.
    if (!(parents instanceof Array)) {
      parents = [parents];
    }

    var ancestorIsIn = function(project, ancestors) {

      var parent = project.getParent();
      var r = false;
      if (parent !== null) {
        jQuery.each(ancestors, function(i, p) {

          // make sure this is a number. when coming from the options
          // array, it might actually be an array of strings.
          if (typeof p === 'string') {
            p = timeline.pnum(p);
          }

          if (parent && p === parent.id) {
            r = true;
          }
        });

        // check rest of project tree. this might break when a project
        // in between is not visible to the current user.
        if (parent) {
          r = r || ancestorIsIn(parent, ancestors);
        }
      }
      return r;
    };

    jQuery.each(projects, function(i, e) {
      if (ancestorIsIn(e, parents)) {
        result.push(e);
      }
    });

    return result;
  },
  getProjectTypes: function() {
    return Timeline.ProjectType.all(this);
  },
  getProjectType: function(id) {
    return this.project_types[id];
  },
  getPlanningElementTypes: function() {
    return Timeline.PlanningElementType.all(this);
  },
  getPlanningElementType: function(id) {
    return this.planning_element_types[id];
  },
  getPlanningElements: function() {
    return Timeline.PlanningElement.all(this);
  },
  getPlanningElement: function(id) {
    return this.planning_elements[id];
  },
  getColors: function() {
    return Timeline.Color.all(this);
  },
  getProjectAssociations: function() {
    return Timeline.ProjectAssociation.all(this);
  },
  getLefthandTree: function() {

    if (!this.lefthandTree) {

      // as long as there are no stored filters or aggregates, we only use
      // the projects as roots.
      var project = this.getProject();
      var tree = Object.create(Timeline.TreeNode);
      var parent_stack = [];

      tree.setData(project);

      // there might not be any payload, due to insufficient rights and
      // the fact that some user with more rights originally created the
      // report.
      if (!project) {
        // FLAG raise some flag indicating that something is
        // wrong/missing.
        return tree;
      }

      var count = 1;
      // for the given node, appends the given planning_elements as children,
      // recursively. every node will have the planning_element as data.
      var treeConstructor = function(node, elements) {
        count += 1;

        var MAXIMUMPROJECTCOUNT = 12000;
        if (count > MAXIMUMPROJECTCOUNT) {
          throw I18n.t('js.timelines.tooManyProjects', {count: MAXIMUMPROJECTCOUNT});
        }

        jQuery.each(elements, function(i, e) {
          parent_stack.push(node.payload);
          for (var j = 0; j < parent_stack.length; j++) {
            if (parent_stack[j] === e) {
              parent_stack.pop();
              return; // no more recursion!
            }
          }
          var newNode = Object.create(Timeline.TreeNode);
          newNode.setData(e);
          node.appendChild(newNode);
          treeConstructor(newNode, newNode.getData().getSubElements());
          parent_stack.pop();
        });
        return node;
      };

      this.lefthandTree = treeConstructor(tree, project.getSubElements());

      this.lefthandTree.expandTo(this.options.initial_outline_expansion);
    }

    return this.lefthandTree;
  }
});

// This polyfill covers the main use case which is creating a new object
// for which the prototype has been chosen but doesn't take the second
// argument into account:
// https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/create
if (!Object.create) {
  Object.create = function(o) {
    if (arguments.length > 1) {
      throw new Error(
        'Object.create implementation only accepts the first parameter.'
      );
    }
    function F() {}
    F.prototype = o;
    return new F();
  };
}
