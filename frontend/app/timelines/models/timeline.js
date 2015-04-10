//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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


module.exports = function(Constants, TreeNode, UI, Color, HistoricalPlanningElement, PlanningElement, PlanningElementType, ProjectType, Project, ProjectAssociation, Reporting, CustomField, CustomFieldHelper) {

  var getInitialValue = function(timelineOptions, property) {
    var value = timelineOptions[property];

    if (value && value >= 0) {
      return value;
    } else {
      return 0;
    }
  };

  var getInitialOutlineExpansion = function(timelineOptions) {
    return getInitialValue(timelineOptions, 'initial_outline_expansion');
  };

  var getInitialZoomFactor = function(timelineOptions) {
    return getInitialValue(timelineOptions, 'zoom_factor');
  };

  Timeline = {};

  // model mix ins
  angular.extend(Timeline, Constants);
  angular.extend(Timeline, UI);

  //startup
  angular.extend(Timeline, {
    instances: [],
    create: function(id, options) {
      if (!id) {
        throw new Error('No timelines id given');
      }
      if (!options) {
        throw new Error('No configuration options given');
      }
      this.extendOptions();

      this.instances = [];

      var timeline = Object.create(Timeline);

      // some private fields.
      timeline.id = id;
      timeline.options = options;
      timeline.listeners = [];
      timeline.data = {};

      timeline.expansionIndex = parseInt(getInitialOutlineExpansion(options), 10);
      timeline.zoomIndex = parseInt(getInitialZoomFactor(options), 10);

      Timeline.instances.push(timeline);
      return timeline;
    },
    extendOptions: function() {
      this.options = jQuery.extend({}, this.defaults, this.options);

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
      // we're hiding the root if there is a grouping.
      this.options.hide_tree_root = this.isGrouping();
    },
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
              return this.die(I18n.t('js.timelines.errors.report_comparison'));
          }
          break; // to please jslint
        case 'absolute':
          value = this.options.compare_to_absolute;
          break;
        case 'historical':
          value = this.options.compare_to_historical_one;
          break;
        default:
          return this.die(I18n.t('js.timelines.errors.report_comparison'));
      }
      return +Date.parse(value)/1000;
    },
    registerTimelineContainer: function(uiRoot) {
      this.uiRoot = uiRoot;
    },
    checkPrerequisites: function() {
      if (jQuery === undefined) {
        throw new Error('jQuery seems to be missing (jQuery is undefined)');
      } else if ((1).month === undefined) {
        throw new Error('date.js seems to be missing ((1).month is undefined)');
      }
      return true;
    },
    getTimelineLoaderOptions: function() {
      return {
        api_prefix                    : this.options.api_prefix,
        url_prefix                    : this.options.url_prefix,
        project_prefix                : this.options.project_prefix,
        planning_element_prefix       : this.options.planning_element_prefix,
        timeline_id                   : this.options.timeline_id,
        project_id                    : this.options.project_id,
        project_types                 : this.options.project_types,
        project_statuses              : this.options.project_status,
        project_responsibles          : this.options.project_responsibles,
        project_parents               : this.options.parents,
        planning_element_types        : this.options.planning_element_types,
        planning_element_assignee     : this.options.planning_element_assignee,
        planning_element_responsibles : this.options.planning_element_responsibles,
        custom_fields                 : this.options.custom_fields,
        planning_element_status       : this.options.planning_element_status,
        grouping_one                  : (this.options.grouping_one_enabled ? this.options.grouping_one_selection : undefined),
        grouping_two                  : (this.options.grouping_two_enabled ? this.options.grouping_two_selection : undefined),
        ajax_defaults                 : this.ajax_defaults,
        current_time                  : this.comparisonCurrentTime(),
        target_time                   : this.comparisonTarget(),
        include_planning_elements     : this.verticalPlanningElementIds()
      };
    },
    die: function(error, classes) {
      var message = (typeof error === 'string') ? error :
        I18n.t('js.timelines.errors.report_epicfail'); // + '<br>' + error.message;
      classes = classes || 'flash error';

      this.warn(message, classes);

      // assume this won't happen anymore.
      this.onLoadComplete = function() {};

      if (console && console.log) {
        console.log(error.stack);
      }

      throw error;
    },
    warn: function(message, classes, viewCallback) {
      var root = this.getUiRoot();

      window.setTimeout(function() {

        // generate and display the error message.
        var warning = jQuery('<div class="' + classes + '">' + message + '</div>');
        root.empty().append(warning);
        if (viewCallback) {
          viewCallback();
        }

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
          this.warn(I18n.t('js.label_no_data'), 'warning');
        }
      } catch (e) {
        this.die(e);
      }
    },
    /* This function calculates the second level grouping adjustments.
     * For every base project it finds all associates with the given project type.
     * It removes every such project from the trees root and adds it underneath the base project.
     */
    secondLevelGroupingAdjustments: function () {
      var grouping = jQuery.map(this.options.grouping_two_selection || [], Timeline.pnum);
      var root = this.getProject();
      var associations = ProjectAssociation.all(this);
      var listToRemove = [];

      // for all projects on the first level
      jQuery.each(root.getReporters(), function (i, reporter) {

        // find all projects that are associated
        jQuery.each(associations, function (j, association) {

          // check if the reporter is involved and hasn't already been included by a second level grouping adjustment
          if (!reporter.hasSecondLevelGroupingAdjustment && association.involves(reporter)) {
            var other = association.getOther(reporter);
            if (typeof other.getProjectType === "function") {
              var projectType = other.getProjectType();
              var projectTypeId = projectType !== null ? projectType.id : -1;

              //check if the type is selected as 2nd level grouping
              if (grouping.indexOf(projectTypeId) !== -1) {
                // add the other project as a simulated reporter to the current one.
                reporter.addReporter(other);
                other.hasSecondLevelGroupingAdjustment = true;
                // remove the project from the root level of the report.
                listToRemove.push(other);

              }
            }
          }
        });
      });

      // remove all children of root that we couldn't remove while still iterating.
      jQuery.each(listToRemove, function(i, reporter) {
        root.removeReporter(reporter);
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
      if (this.options.timeframe_start) {
        return moment(this.options.timeframe_start).toDate();
      }
      var startDate = new Date();
      if (this.firstDateSeen) {
        startDate = this.firstDateSeen.clone();
      }
      return startDate.last().monday();
    },
    getEnd: function() {
      if (this.options.timeframe_end) {
        return moment(this.options.timeframe_end).toDate();
      }
      var endDate = new Date();
      if (this.lastDateSeen) {
        endDate = this.lastDateSeen.clone();
      }
      return endDate.addWeeks(1).next().sunday();

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
        if (data.is(PlanningElement)) {
          timeline.includeDate(data.start());
          timeline.includeDate(data.end());
        }
      }, {
        traverseCollapsed: true
      });

    },
    getCustomFieldColumns: function() {
      return this.options.columns.filter(function(column) {
        return CustomFieldHelper.isCustomFieldKey(column);
      });
    },
    getCustomFields: function() {
      var customFields = [];

      jQuery.each(this.custom_fields, function(key, customField) {
        customFields.push(customField);
      });

      return customFields;
    },
    getValidCustomFieldIds: function() {
      return this.getCustomFields().map(function(cf) {
        return cf.id;
      });
    },
    getInvalidCustomFieldColumns: function() {
      var validCustomFieldIds = this.getValidCustomFieldIds();
      var timeline = this;

      return this.getCustomFieldColumns().filter(function(cfColumn) {
        return validCustomFieldIds.indexOf(CustomFieldHelper.getCustomFieldId(cfColumn)) === -1;
      });
    },
    removeColumnByName: function(columnName) {
      this.options.columns.splice(this.options.columns.indexOf(columnName), 1);
    },
    clearUpCustomFieldColumns: function() {
      var timeline = this;

      jQuery.each(this.getInvalidCustomFieldColumns(), function(i, cfColumn) {
        timeline.removeColumnByName(cfColumn);
      });
    },
    getReportings: function() {
      return Reporting.all(this);
    },
    getReporting: function(id) {
      return this.reportings[id];
    },
    getProjects: function() {
      return Project.all(this);
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
        'name': I18n.t('js.timelines.filter.grouping_other')
      };
    },

    firstLevelGroups: undefined,
    getFirstLevelGroups: function() {
      if (this.firstLevelGroups !== undefined) {
        return this.firstLevelGroups;
      }
      var i, selection = this.options.grouping_one_selection;
      var p, groups = [], children;
      if (this.isGrouping() && selection) {
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
      if (!(Array.isArray(parents))) {
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
      return ProjectType.all(this);
    },
    getProjectType: function(id) {
      return this.project_types[id];
    },
    getPlanningElementTypes: function() {
      return PlanningElementType.all(this);
    },
    getPlanningElementType: function(id) {
      return this.planning_element_types[id];
    },
    getPlanningElements: function() {
      return PlanningElement.all(this);
    },
    getPlanningElement: function(id) {
      return this.planning_elements[id];
    },
    getColors: function() {
      return Color.all(this);
    },
    getProjectAssociations: function() {
      return ProjectAssociation.all(this);
    },
    getLefthandTree: function() {

      if (!this.lefthandTree) {

        // as long as there are no stored filters or aggregates, we only use
        // the projects as roots.
        var project = this.getProject();
        var tree = Object.create(TreeNode);
        var parent_stack = [];

        tree.setData(project, 0);

        // there might not be any payload, due to insufficient rights and
        // the fact that some user with more rights originally created the
        // report.
        if (!project) {
          // FLAG raise some flag indicating that something is
          // wrong/missing.
          return tree;
        }

        var level = 1;
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
            var newNode = Object.create(TreeNode);

            newNode.setData(e, level);
            node.appendChild(newNode);

            level++;
            treeConstructor(newNode, newNode.getData().getSubElements());
            level--;

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

  return Timeline;
};
