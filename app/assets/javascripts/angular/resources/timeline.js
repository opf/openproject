timelinesApp.factory('Timeline', ['$q', '$filter', 'Constants', 'FilterQueryStringBuilder', 'TreeNode', 'UI', 'Color', 'HistoricalPlanningElement', 'PlanningElement', 'PlanningElementType', 'Project', 'ProjectAssociation', 'ProjectType', 'Reporting', 'Status', 'User', function($q, $filter, Constants, FilterQueryStringBuilder, TreeNode, UI, Color, HistoricalPlanningElement, PlanningElement, PlanningElementType, Project, ProjectAssociation, ProjectType, Reporting, Status, User) {

  Timeline = {};

  angular.extend(Timeline, Constants);
  Timeline.FilterQueryStringBuilder = FilterQueryStringBuilder;
  angular.extend(Timeline, {TreeNode: TreeNode});
  angular.extend(Timeline, UI);

  angular.extend(Timeline, {
    instances: [],
    create: function(options) {
      if (!options) {
        throw new Error('No configuration options given');
      }
      this.options = options;
      this.extendOptions();

      this.instances = [];


      var timeline = Object.create(Timeline);

      // some private fields.
      timeline.listeners = [];
      timeline.data = {};

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
      console.log('- timeline.js: comparisonTarget');

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
    registerTimelineContainer: function(uiRoot) {
      console.log('- timelines.js: registerTimelineContainer');

      this.uiRoot = uiRoot;
      this.registerDrawPaper();
    },
    checkPrerequisites: function() {
      console.log('- timelines.js: checkPrerequisites');

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
      console.log('- timelines.js: reload');

      delete this.lefthandTree;
      // reload data
      // then
        //  if (this.isGrouping() && this.options.grouping_two_enabled) {
        //   this.secondLevelGroupingAdjustments();
        // }

        // this.adjustForPlanningElements();

        // this.rebuildAll();
    },
    // getOptionsForLoading: function() {
    //   return {
    //     api_prefix                    : this.options.api_prefix,
    //     url_prefix                    : this.options.url_prefix,
    //     project_prefix                : this.options.project_prefix,
    //     planning_element_prefix       : this.options.planning_element_prefix,
    //     project_id                    : this.options.project_id,
    //     project_types                 : this.options.project_types,
    //     project_statuses              : this.options.project_status,
    //     project_responsibles          : this.options.project_responsibles,
    //     project_parents               : this.options.parents,
    //     planning_element_types        : this.options.planning_element_types,
    //     planning_element_responsibles : this.options.planning_element_responsibles,
    //     planning_element_status       : this.options.planning_element_status,
    //     grouping_one                  : (this.options.grouping_one_enabled ? this.options.grouping_one_selection : undefined),
    //     grouping_two                  : (this.options.grouping_two_enabled ? this.options.grouping_two_selection : undefined),
    //     ajax_defaults                 : this.ajax_defaults,
    //     current_time                  : this.comparisonCurrentTime(),
    //     target_time                   : this.comparisonTarget(),
    //     include_planning_elements     : this.verticalPlanningElementIds()
    //   };
    // },
    die: function(error, classes) {
      var message = (typeof error === 'string') ? error :
        this.i18n('timelines.errors.report_epicfail'); // + '<br>' + error.message;
      classes = classes || 'flash error';

      this.warn(message, classes);

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
    completeDrawing: function() {
      var tree;
      try {
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
      console.log('- timelines.js: secondLevelGroupingAdjustments');

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



  // (2.)

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Defaults and random accessors                                     │
  // ╰───────────────────────────────────────────────────────────────────╯
  angular.extend(Timeline, {
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
        if (this.firstDateSeen === null ||
            date.compareTo(this.firstDateSeen) < 0) {
          this.firstDateSeen = date;
        } else if (this.lastDateSeen === null ||
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


    // Promise API

    // Associated objects

    getProject: function() {
      return Project.getById(this.options.project_id);
    },

    getRelevantProjects: function() {
      return this.getProject()
        .then(function(project){
          return project.getSelfAndReportingProjects();
        });
    },

    getRelevantProjectIds: function () {
      return this.getRelevantProjects()
        .then(function(relevantProjects){
          return relevantProjects.map(function(project){
            return project.id;
          });
        });
    },

    // getRelevantProjectIdsForApiPath: function () {
    //   relevantProjectIds = [];
    //   return this.getProject()
    //     .then(function(project){
    //       relevantProjectIds.push(project.identifier);
    //       return project.getReportingProjects();
    //     })
    //     .then(function(reportingProjects){
    //       angular.forEach(reportingProjects,function(project){
    //         relevantProjectIds.push(project.id);
    //       });
    //       return relevantProjectIds;
    //     });
    // },

    getProjects: function() {
      return this.getRelevantProjects();
      // TODO Filter reportings
      //   if (this.reportings.hasOwnProperty(i)) {
      //     relevantProjectIds.push(this.reportings[i].getProjectId());
      //   }
    },

    getReportings: function() {
      return this.getProject().then(function(project){
        return project.getReportings();
      });
    },

    getReportingById: function(id) {
      return this.getReportings().then(function(reportings){
        return $filter('getElementById')(reportings, id);
      });
    },


    getGroupForProject: function(p) {
      var i, j = 0, projects, key, group;
      return this.getFirstLevelGroups()
        .then(function(groups){
          for (j = 0; j < groups.length; j += 1) {
            projects = groups[j].projects;
            this.getProject(groups[j].id).then(function(group){
              // TODO check if the promises graph is resolved such that projects aren't loaded multiple times, or better, keep project object in groups
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
              return {
                'number': 0,
                'id': 0,
                'name': this.i18n('timelines.filter.grouping_other')
              };
              // TODO refactoring
            });
          }

        });
    },

    getFirstLevelGroups: function() {
      var i, selection = this.options.grouping_one_selection;
      var p, groups = [];

      if (this.isGrouping()) {
        return this.getProjects()
          .then(function(projects){
            for ( i = 0; i < selection.length; i++ ) {
              project = projects[selection[i]];
              if (project === undefined) {
                // projects may have subprojects that the current user knows
                // about, but which cannot be/ were not fetched in advance due
                // to lack of rights.
                continue;
              }
              project.getSubprojects()
                .then(function(subprojects){
                  if (subprojects.length !== 0) {
                    groups.push({
                      projects: subprojects,
                      id: selection[i]
                    });
                  }
                });
            }
            return groups;
          });
      } else {
        return $q.when([]);
      }

    },
    getNumberOfGroups: function() {
      var result = this.options.hide_other_group? 0: 1;
      var groups = this.getFirstLevelGroups();
      return result + groups.length;
    },
    getProjectTypes: function() {
      ProjectType.getCollection();
    },
    getProjectType: function(id) {
      return ProjectType.getById(id);
    },
    getPlanningElementTypes: function() {
      return PlanningElementType.getCollection();
    },
    getPlanningElementType: function(id) {
      return PlanningElementType.getById(id);
    },
    getPlanningElements: function() {
      return this.getRelevantProjectIds()
        .then(function(projectIds){
          return PlanningElement.getCollection(projectIds);
        });
    },
    getPlanningElement: function(id) {
      return this.planning_elements[id];
    },
    getColors: function() {
      return Color.getCollection();
    },
    getProjectAssociations: function() {
      return ProjectAssociation.all(this);
    },
    getLefthandTree: function() {
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

      return this.getProject()
        .then(function(project){
          // as long as there are no stored filters or aggregates, we only use
          // the projects as roots.
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

          lefthandTree = treeConstructor(tree, project.getSubElements());
          lefthandTree.expandTo(this.options.initial_outline_expansion);

          return lefthandTree;
        });

    }
  });

  return Timeline;
}]);
