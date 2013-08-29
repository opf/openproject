//-- copyright
// OpenProject is a project management system.
//
// Copyright (C) 2012-2013 the OpenProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

// ╭───────────────────────────────────────────────────────────────╮
// │ Timeines Plugin Javascript Library.                           │
// ├───────────────────────────────────────────────────────────────┤
// │ Javascript Library that fetches and plots timelines for the   │
// │ accompanying ChiliProject Plugin. Martin Czuchra, Finn GmbH   │
// │ 2011                                                          │
// ╰───────────────────────────────────────────────────────────────╯

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

Timeline = {

  LOAD_ERROR_TIMEOUT: 60000,
  DISPLAY_ERROR_DELAY: 2000,
  PROJECT_ID_BLOCK_SIZE: 100,

  defaults: {
    artificial_load_delay:          0,   // no delay
    columns:                        [],
    exclude_own_planning_elements:  false,
    exclude_reporters:              false,
    api_prefix:                     '/api/v2',
    hide_other_group:               false,
    hide_tree_root:                 false,
    i18n:                           {},  // undefined would be bad.
    initial_outline_expansion:      0,   // aggregations only
    project_prefix:                 '/projects',
    planning_element_prefix:        '',
    ui_root:                        jQuery('#timeline'),
    url_prefix:                     ''   // empty prefix so it is not undefined.
  },

  ajax_defaults: {
    cache: false,
    context: this,
    dataType: 'json'
  },

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

      this.modalHelper = new ModalHelper(
        this,
        {
          api_prefix                : this.options.api_prefix,
          url_prefix                : this.options.url_prefix,
          project_prefix            : this.options.project_prefix
        }
      );
      this.modalHelper.setup();

      timelineLoader = new Timeline.TimelineLoader(
        this,
        {
          api_prefix                : this.options.api_prefix,
          url_prefix                : this.options.url_prefix,
          project_prefix            : this.options.project_prefix,
          planning_element_prefix   : this.options.planning_element_prefix,
          project_id                : this.options.project_id,
          project_types             : this.options.project_types,
          project_statuses          : this.options.project_status,
          project_responsibles      : this.options.project_responsibles,
          project_parents           : this.options.parents,
          grouping_one              : (this.options.grouping_one_enabled ? this.options.grouping_one_selection : undefined),
          grouping_two              : (this.options.grouping_two_enabled ? this.options.grouping_two_selection : undefined),
          ajax_defaults             : this.ajax_defaults,
          current_time              : this.comparisonCurrentTime(),
          target_time               : this.comparisonTarget(),
          include_planning_elements : this.verticalPlanningElementIds()
        }
      );

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
  reload: function() {
    delete this.lefthandTree;
    var timelineLoader = new Timeline.TimelineLoader(
        this,
        {
          api_prefix                : this.options.api_prefix,
          url_prefix                : this.options.url_prefix,
          project_prefix            : this.options.project_prefix,
          planning_element_prefix   : this.options.planning_element_prefix,
          project_id                : this.options.project_id,
          project_types             : this.options.project_types,
          project_statuses          : this.options.project_status,
          project_responsibles      : this.options.project_responsibles,
          project_parents           : this.options.parents,
          grouping_one              : (this.options.grouping_one_enabled ? this.options.grouping_one_selection : undefined),
          grouping_two              : (this.options.grouping_two_enabled ? this.options.grouping_two_selection : undefined),
          ajax_defaults             : this.ajax_defaults,
          current_time              : this.comparisonCurrentTime(),
          target_time               : this.comparisonTarget(),
          include_planning_elements : this.verticalPlanningElementIds()
        }
    );

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

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Loading                                                           │
  // ╰───────────────────────────────────────────────────────────────────╯
  TimelineLoader : (function () {

    /**
     * QueueingLoader
     *
     * Simple wrapper around jQuery.ajax, which introduces two step loading
     * of remote data.
     *
     * Step 1: register URL and meta information using `register`
     * Step 2: load all registered elements using `load`
     *
     * To notify consumers about AJAX responses, the QueueingLoader uses
     * the jQuery custom event system. Whenever a request is complete,
     * success or error events will be triggered. When the queue is empty,
     * an 'empty' event will be triggered. Use the callback functions like
     * the following ones, to react on these events:
     *
     *     jQuery(myLoader).on("success", function (e, args) {
     *       console.log("'success' triggered for", this);
     *       console.log("identifier used in register:",  args.identifier);
     *       console.log("context provided in register:", args.context);
     *       console.log("data returned by the server:",  args.data);
     *     });
     *
     *     jQuery(myLoader).on("error", function (e, args) {
     *       console.log("'error' triggered for ", this);
     *       console.log("identifier used in register:",  args.identifier);
     *       console.log("context provided in register:", args.context);
     *       console.log("textStatus provided by jqXHR:", args.textStatus);
     *     });
     *
     *     jQuery(myLoader).on("empty", function (e) {
     *       console.log("'empty' triggered for ", this);
     *     });
     *
     */
    var QueueingLoader = function (ajaxDefaults) {
      this.ajaxDefaults = ajaxDefaults;
      this.registered   = {};
      this.loading      = {};
    };

    /**
     * Enqueue new elements to load
     *
     * identifier should be a string and uniq. If identifier is used twice, then
     *            bad things will happen.
     *
     * options should be the options passed to jQuery.ajax. Often it is enough,
     *         to provide a URL.
     *
     * context additional information which will be passed to the callbacks. Use
     *         this to store some state.
     */
    QueueingLoader.prototype.register = function (identifier, options, context) {
      this.registered[identifier] = {
        options : options,
        context : context || {}
      };
    };

    /**
     * Trigger loading of all registered elements
     */
    QueueingLoader.prototype.load = function () {
      var identifier, element;

      for (identifier in this.registered) {
        if (this.registered.hasOwnProperty(identifier)) {
          element = this.registered[identifier];
          delete this.registered[identifier];

          this.loadElement(identifier, element);
        }
      }
    };

    QueueingLoader.prototype.getRegisteredIdentifiers = function () {
      return jQuery.map(this.registered, function (e, i) { return i; });
    };

    QueueingLoader.prototype.getLoadingIdentifiers = function () {
      return jQuery.map(this.loading, function (e, i) { return i; });
    };

    // Methods below are not meant to be public
    QueueingLoader.prototype.loadElement = function (identifier, element) {

      element.options = jQuery.extend(
          {},
          this.ajaxDefaults,
          element.options,
          {
            success  : function(data, textStatus, jqXHR) {
              delete this.loading[identifier];

              jQuery(this).trigger('success', {identifier : identifier,
                                               context    : element.context,
                                               data       : data});
            },

            error    : function (jqXHR, textStatus, errorThrown) {
              delete this.loading[identifier];

              jQuery(this).trigger('error', {identifier : identifier,
                                             context    : element.context,
                                             textStatus : textStatus});
            },

            complete : this.onComplete,

            context  : this
          }
      );

      this.loading[identifier] = element;

      jQuery.ajax(element.options);
    };

    QueueingLoader.prototype.onComplete = function () {
      // count remainders
      var remaining = 0;
      for (var key in this.loading) {
        if (this.loading.hasOwnProperty(key)) {
          remaining++;
        }
      }

      // if nothing remains, notify about empty queue
      if (remaining === 0) {
        jQuery(this).trigger('empty');
      }
    };

    var DataEnhancer = function (timeline) {
      this.timeline = timeline;

      this.options = {
        projectId : timeline.options.project_id
      };

      this.die = function () {
        timeline.die.apply(timeline, arguments);
      };
    };

    DataEnhancer.getBasicType = function (identifier) {
      var i, basicTypes = this.BasicTypes();

      for (i = 0; i < basicTypes.length; i++) {
        if (basicTypes[i].identifier === identifier) {
          return basicTypes[i];
        }
      }
    };

    DataEnhancer.BasicTypes = function () {
      return [
        Timeline.Color,
        Timeline.PlanningElementType,
        Timeline.HistoricalPlanningElement,
        Timeline.PlanningElement,
        Timeline.ProjectType,
        Timeline.Project,
        Timeline.ProjectAssociation,
        Timeline.Reporting
      ];
    };

    DataEnhancer.prototype.createObjects = function (data, identifier) {
      var type = DataEnhancer.getBasicType(identifier);

      var i, e, id, map = {};

      if (data instanceof Array) {
        for (i = 0; i < data.length; i++) {
          e = data[i];
          e.timeline = this.timeline;
          id = e.id;
          map[id] = jQuery.extend(Object.create(type), e);
        }
      }
      else {
        console.warn("Expected instance of Array, but got something else.", data, identifier);
      }

      return map;
    };

    DataEnhancer.prototype.enhance = function (data) {
      try {

        this.data = data;

        this.createEmptyElementMaps();
        this.assignMainProject();

        this.augmentReportingsWithProjectObjects();
        this.augmentProjectsWithProjectTypesAndAssociations();

        this.removeTrashedPlanningElements();

        this.augmentPlanningElementsWithHistoricalData();
        this.augmentPlanningElementsWithProjectAndParentAndChildInformation();
        this.augmentPlanningElementsWithVerticalityData();

        return this.data;

      } catch(e) {
        this.die(e);
      }
    };

    DataEnhancer.prototype.createEmptyElementMaps = function () {
      if (!this.data.hasOwnProperty(Timeline.ProjectAssociation.identifier)) {
        this.data[Timeline.ProjectAssociation.identifier] = {};
      }
    };

    DataEnhancer.prototype.getElementMap = function (type) {
      return this.data[type.identifier];
    };

    DataEnhancer.prototype.setElementMap = function (type, map) {
      if (map === undefined) {
        delete this.data[type.identifier];
      }
      else {
        this.data[type.identifier] = map;
      }
      return map;
    };

    DataEnhancer.prototype.getElements = function (type) {
      var map    = this.getElementMap(type) || {},
          result = [];

      for (var key in map) {
        if (map.hasOwnProperty(key)) {
          result.push(map[key]);
        }
      }
      return result;
    };

    DataEnhancer.prototype.getElement = function (type, id) {
      return this.data[type.identifier][id];
    };

    DataEnhancer.prototype.setElement = function (type, id, element) {
      return this.data[type.identifier][id] = element;
    };

    DataEnhancer.prototype.getProject = function () {
      return this.data.project;
    };

    DataEnhancer.prototype.setProject = function (project) {
      this.data.project = project;
      return project;
    };


    DataEnhancer.prototype.assignMainProject = function () {
      if (this.getProject() !== undefined) {
        return;
      }

      var dataEnhancer = this;

      // looking for main project in timeline.projects array and storing it as
      // primary project in timeline.project
      jQuery.each(this.getElements(Timeline.Project), function (i, e) {
        if (e.identifier === dataEnhancer.options.projectId ||
            e.id         === dataEnhancer.options.projectId) {

          dataEnhancer.setProject(e);
        }
      });

      if (dataEnhancer.getProject() === undefined) {
        dataEnhancer.die(new Error("Could not find main project. " +
          "The current user is probably not allowed to view timelines in here."));
      }
    };

    DataEnhancer.prototype.augmentReportingsWithProjectObjects = function () {
      var dataEnhancer = this;

      jQuery.each(dataEnhancer.getElements(Timeline.Reporting), function (i, reporting) {
        var project  = dataEnhancer.getElement(Timeline.Project, reporting.reporting_to_project.id);
        var reporter = dataEnhancer.getElement(Timeline.Project, reporting.project.id);

        // there might not be a project, which due to insufficient rights
        // and the fact that some user with more rights originally created
        // the report, is not available here.
        if (!project || !reporter) {
          // TODO some flag indicating that something is wrong/missing.
          return;
        }

        reporting.reporting_to_project = project;
        reporting.project = reporter;

        reporter.via_reporting = reporting;

        // project ← reporting → project
        if (project.reporters === undefined) {
          project.reporters = [];
        }
        if (jQuery.inArray(reporter, project.reporters) === -1) {
          project.reporters.push(reporter);
        }
      });
    };

    DataEnhancer.prototype.augmentProjectsWithProjectTypesAndAssociations = function () {
      var dataEnhancer    = this;

      jQuery.each(dataEnhancer.getElements(Timeline.Project), function (i, e) {

        // project_type ← project
        if (e.project_type !== undefined) {
          var project_type = dataEnhancer.getElement(Timeline.ProjectType, e.project_type.id);

          if (project_type) {
            e.project_type = project_type;
          }
        }

        // project ← association → project

        var associations = e[Timeline.ProjectAssociation.identifier];
        var j, a, other;

        if (associations instanceof Array) {
          for (j = 0; j < associations.length; j++) {
            a = associations[j];
            a.timeline = dataEnhancer.timeline;
            a.origin = e;

            other = dataEnhancer.getElement(Timeline.Project, a.project.id);
            if (other) {
              a.project = other;
              dataEnhancer.setElement(
                  Timeline.ProjectAssociation,
                  a.id,
                  jQuery.extend(Object.create(Timeline.ProjectAssociation), a));
            }

          }
        }

        // project → parent
        if (e.parent) {
          e.parent = dataEnhancer.getElement(Timeline.Project, e.parent.id);
        }
        else {
          e.parent = undefined;
        }
      });
    };

    DataEnhancer.prototype.removeTrashedPlanningElements = function () {
      var dataEnhancer = this;
      jQuery.each(dataEnhancer.getElements(Timeline.PlanningElement), function (i, e) {
         if (e.in_trash) {
          delete dataEnhancer.data[Timeline.PlanningElement.identifier][e.id];
         }
      });
    };

    DataEnhancer.prototype.augmentPlanningElementsWithHistoricalData = function () {
      var dataEnhancer = this;

      jQuery.each(dataEnhancer.getElements(Timeline.HistoricalPlanningElement), function (i, e) {
        var pe = dataEnhancer.getElement(Timeline.PlanningElement, e.id);

        if (pe === undefined) {

          // The planning element is in the historical data, but not in
          // the current set of planning elements, i.e. it was deleted
          // in the compared timeframe. We therefore import the deleted
          // element into the planning elements array and set the
          // is_deleted flag.
          e = jQuery.extend(Object.create(Timeline.PlanningElement), e);
          e.is_deleted = true;
          dataEnhancer.setElement(Timeline.PlanningElement, e.id, e);
          pe = e;
        }

        pe.alternate_start_date = e.start_date;
        pe.alternate_end_date = e.end_date;
      });

      dataEnhancer.setElementMap(Timeline.HistoricalPlanningElement, undefined);
    };

    DataEnhancer.prototype.augmentPlanningElementsWithProjectAndParentAndChildInformation = function () {
      var dataEnhancer = this;

      jQuery.each(dataEnhancer.getElements(Timeline.PlanningElement), function (i, e) {
        var project = dataEnhancer.getElement(Timeline.Project, e.project.id);


        // planning_element → planning_element_type
        if (e.planning_element_type) {
          e.planning_element_type = dataEnhancer.getElement(Timeline.PlanningElementType,
                                                            e.planning_element_type.id);
        }
        else {
          e.planning_element_type = undefined;
        }

        // there might not be such a project, due to insufficient rights
        // and the fact that some user with more rights originally created
        // the report.
        if (!project) {
          // TODO some flag indicating that something is wrong/missing.
          return;
        }

        // planning_element → project
        e.project = project;

        if (e.parent) {
          var parent = dataEnhancer.getElement(Timeline.PlanningElement, e.parent.id);

          if (parent !== undefined) {

            // planning_element ↔ planning_element
            if (parent.planning_elements === undefined) {
              parent.planning_elements = [];
            }
            parent.planning_elements.push(e);
            e.parent = parent;
          }

        } else {

          // planning_element ← project
          if (project.planning_elements === undefined) {
            project.planning_elements = [];
          }
          project.planning_elements.push(e);
        }
      });
    };

    DataEnhancer.prototype.augmentPlanningElementsWithVerticalityData = function () {
      var dataEnhancer = this;

      jQuery.each(dataEnhancer.getElements(Timeline.PlanningElement), function (i, e) {
        var pe = dataEnhancer.getElement(Timeline.PlanningElement, e.id);
        var pet = pe.getPlanningElementType();

        if (!pe.in_trash) {
          pe.vertical = this.timeline.verticalPlanningElementIds().indexOf(pe.id) != -1;
        }
        //this.timeline.optionsfalse || Math.random() < 0.5 || (pet && pet.is_milestone);
      });
    };

    /**
     *  TimelineLoader
     *
     *  Loads all data, that is relevant for the current timeline instance.
     *
     *  timeline: Timeline instance
     *  options:  Configuration Hash
     *
     *  The timeline parameter is used to augment the loaded data with pointers
     *  to their coressponding timeline. No assumptions about methods or
     *  attributes are made.
     *
     *  The following list describes the required options
     *
     *    url_prefix     : timeline.options.url_prefix,
     *    project_prefix : timeline.options.project_prefix,
     *    project_id     : timeline.options.project_id,
     *
     *    ajax_defaults  : timeline.ajax_defaults
     *
     *    current_time   : this.comparisonCurrentTime(),
     *    target_time    : this.comparisonTarget()
     *
     *  Use `load` to trigger loading of data.
     *  Use events to get notified about completion
     *
     *      jQuery(timelineLoader).on("complete", function (e, data) {
     *        console.log("'complete' triggered for", this);
     *        console.log("Loaded data is:", data);
     *      }
     */
    var TimelineLoader = function (timeline, options) {
      this.options      = options;
      this.data         = {};
      this.loader       = new QueueingLoader(options.ajax_defaults);
      this.dataEnhancer = new DataEnhancer(timeline);

      this.globalPrefix = options.url_prefix + options.api_prefix;

      jQuery(this.loader).on('success', jQuery.proxy(this, 'onLoadSuccess'))
                         .on('error',   jQuery.proxy(this, 'onLoadError'))
                         .on('empty',   jQuery.proxy(this, 'onLoadComplete'));
    };


    TimelineLoader.prototype.load = function () {
      this.registerProjectReportings();
      this.registerGlobalElements();

      this.loader.load();
    };

    TimelineLoader.prototype.onLoadSuccess = function (e, args) {
      var storeIn  = args.context.storeIn  || args.identifier,
          readFrom = args.context.readFrom || storeIn;

      this.storeData(args.data[readFrom], storeIn);
      this.checkDependencies(args.identifier);
    };

    TimelineLoader.prototype.onLoadError = function (e, args) {
      var storeIn  = args.context.storeIn  || args.identifier;

      console.warn("Error during loading", arguments);

      this.storeData([], storeIn);

      this.checkDependencies(args.identifier);
    };

    TimelineLoader.prototype.onLoadComplete = function (e) {
      jQuery(this).trigger('complete', this.dataEnhancer.enhance(this.data));
    };

    TimelineLoader.prototype.registerProjectReportings = function () {
      var projectPrefix = this.options.url_prefix +
                          this.options.api_prefix +
                          this.options.project_prefix +
                          "/" +
                          this.options.project_id;

      var url = projectPrefix + '/reportings.json?only=via_target';

      if (this.options.project_types) {
        url += '&project_types=' + this.options.project_types.join();
      }

      if (this.options.project_statuses) {
        url += '&project_statuses=' + this.options.project_statuses.join();
      }

      if (this.options.project_responsibles) {
        url += '&project_responsibles=' + this.options.project_responsibles.join();
      }

      if (this.options.project_parents) {
        url += '&project_parents=' + this.options.project_parents.join();
      }

      if (this.options.grouping_one) {
        url += '&grouping_one=' + this.options.grouping_one.join();
      }

      if (this.options.grouping_two) {
        url += '&grouping_two=' + this.options.grouping_two.join();
      }

      this.loader.register(Timeline.Reporting.identifier,
                           { url : url });
    },

    TimelineLoader.prototype.registerGlobalElements = function () {

      this.loader.register(
          Timeline.PlanningElementType.identifier,
          { url : this.globalPrefix + '/planning_element_types.json' });
      this.loader.register(
          Timeline.Color.identifier,
          { url : this.globalPrefix + '/colors.json' });
      this.loader.register(
          Timeline.ProjectType.identifier,
          { url : this.globalPrefix + '/project_types.json' });
    };

    TimelineLoader.prototype.registerProjects = function (ids) {

      this.inChunks(ids, function (project_ids_of_packet, i) {

        this.loader.register(
            Timeline.Project.identifier + '_' + i,
            { url : this.globalPrefix +
                    '/projects.json?ids=' +
                    project_ids_of_packet.join(',')},
            { storeIn : Timeline.Project.identifier }
          );
      });
    };

    TimelineLoader.prototype.registerPlanningElements = function (ids) {

      this.inChunks(ids, function (projectIdsOfPacket, i) {
        var projectPrefix = this.options.url_prefix +
                            this.options.api_prefix +
                            this.options.project_prefix +
                            "/" +
                            projectIdsOfPacket.join(',');

        // load current planning elements.
        this.loader.register(
            Timeline.PlanningElement.identifier + '_' + i,
            { url : projectPrefix +
                    '/planning_elements.json?exclude=scenarios' +
                    this.comparisonCurrentUrlSuffix()},
            { storeIn: Timeline.PlanningElement.identifier }
          );

        // load historical planning elements.
        if (this.options.target_time) {
          this.loader.register(
              Timeline.HistoricalPlanningElement.identifier + '_' + i,
              { url : projectPrefix +
                      '/planning_elements.json?exclude=scenarios' +
                      this.comparisonTargetUrlSuffix() },
              { storeIn: Timeline.HistoricalPlanningElement.identifier,
                readFrom: Timeline.PlanningElement.identifier }
            );
        }
      });
    };


    TimelineLoader.prototype.registerPlanningElementsByID = function (ids) {

      this.inChunks(ids, function (planningElementIdsOfPacket, i) {
        var planningElementPrefix = this.options.url_prefix +
                            this.options.planning_element_prefix;

        // load current planning elements.
        this.loader.register(
            Timeline.PlanningElement.identifier + '_IDS_' + i,
            { url : planningElementPrefix +
                    '/planning_elements.json?ids=' +
                    planningElementIdsOfPacket.join(',')},
            { storeIn: Timeline.PlanningElement.identifier }
          );

        /* TODO!
        // load historical planning elements.
        if (this.options.target_time) {
          this.loader.register(
              Timeline.HistoricalPlanningElement.identifier + '_IDS_' + i,
              { url : planningElementPrefix +
                      '/planning_elements.json?ids=' +
                      planningElementIdsOfPacket.join(',') },
              { storeIn: Timeline.HistoricalPlanningElement.identifier,
                readFrom: Timeline.PlanningElement.identifier }
            );
        }
        */
      });
    };

    TimelineLoader.prototype.inChunks = function (elements, iter) {
      var i, current_elements;

      i = 0;
      elements = elements.clone();

      while (elements.length > 0) {
        i++;

        current_elements = elements.splice(0, Timeline.PROJECT_ID_BLOCK_SIZE);

        iter.call(this, current_elements, i);
      }
    };

    TimelineLoader.prototype.comparisonCurrentUrlSuffix = function () {
      if (this.options.current_time !== undefined) {
        return "&at=" + this.options.current_time;
      } else {
        return "";
      }
    };

    TimelineLoader.prototype.comparisonTargetUrlSuffix = function () {
      if (this.options.target_time !== undefined ) {
        return "&at=" + this.options.target_time;
      } else {
        return "";
      }
    };

    TimelineLoader.prototype.storeData = function (data, identifier) {
      if (!jQuery.isArray(data)) {
        this.die("Expected an instance of Array. Got something else. This " +
                 "should never happen.", data, identifier);
      }

      this.data[identifier] = this.data[identifier] || {};
      jQuery.extend(
          this.data[identifier],
          this.dataEnhancer.createObjects(data, identifier));
    };

    TimelineLoader.prototype.getCurrentlyLoadingTypes = function (unique) {
      var currentlyLoadingTypes = [], m = {};

      jQuery.each(this.loader.getLoadingIdentifiers(), function (i, e) {
        currentlyLoadingTypes.push(e.replace(/_\d+$/, ''));
      });

      if (unique) {
        jQuery.each(currentlyLoadingTypes, function (i, e) { m[e] = e; });
        currentlyLoadingTypes = [];
        jQuery.each(m, function (i, e) { currentlyLoadingTypes.push(e); });
      }

      return currentlyLoadingTypes;
    };

    TimelineLoader.prototype.doneLoading = function (param) {
      if (typeof param !== 'string') {
        param = param.identifier;
      }
      if (param === Timeline.Project.identifier ||
          param === Timeline.PlanningElement.identifier) {

        return jQuery.inArray(param, this.getCurrentlyLoadingTypes()) === -1;
      }
      else {
        return this.data[param] !== undefined;
      }
    };

    TimelineLoader.prototype.getRemainingPlanningElements = function () {
      var i,
        necessaryIDs = [],
        vp = this.options.include_planning_elements;

      for (i = 0; i < vp.length; i += 1) {
        if (typeof this.data.planning_elements[vp[i]] === "undefined") {
          necessaryIDs.push(vp[i]);
        }
      }

      return necessaryIDs;
    };

    TimelineLoader.prototype.getRelevantProjectIdsBasedOnReportings = function () {
      var i,
          relevantProjectIds = [this.options.project_id];

      if (this.doneLoading(Timeline.Reporting)) {
        for (i in this.data.reportings) {
          if (this.data.reportings.hasOwnProperty(i)) {
            relevantProjectIds.push(this.data.reportings[i].getProjectId());
          }
        }

        this.getRelevantProjectIdsBasedOnReportings = function () {
          return relevantProjectIds;
        };
      }
      else {
        console.warn("Getting relevant project ids before reportings are " +
                     "loaded. This might be a bug.");
      }

      return relevantProjectIds;
    };

    TimelineLoader.prototype.getProject = function (idOrIdentifier) {
      var i, ps = this.data.projects;

      if (typeof idOrIdentifier === 'string') {
        for (i in ps) {
          if (ps.hasOwnProperty(i) && ps[i].identifier === idOrIdentifier) {
            return ps[i];
          }
        }
      }
      else {
        return this.data.projects[idOrIdentifier];
      }
    };

    TimelineLoader.prototype.getRelevantProjectIdsBasedOnProjects = function () {
      var relevantProjectIds = this.getRelevantProjectIdsBasedOnReportings(),
          timelineLoader     = this;

      if (this.doneLoading(Timeline.Project)) {
        relevantProjectIds = jQuery.grep(relevantProjectIds, function (e, i) {
          return timelineLoader.getProject(e) && timelineLoader.getProject(e).filteredOut();
        }, true);

        this.getRelevantProjectIdsBasedOnProjects = function () {
          return relevantProjectIds;
        };
      }
      else {
        console.warn("Getting relevant project ids before projects are " +
                     "loaded. This might be a bug.");
      }

      return relevantProjectIds;
    };

    TimelineLoader.prototype.shouldLoadReportings = function (lastLoaded) {
      return lastLoaded === Timeline.Reporting.identifier;
    };

    TimelineLoader.prototype.shouldLoadPlanningElements = function (lastLoaded) {

      if (this.doneLoading(Timeline.Project) &&
          this.doneLoading(Timeline.Reporting) &&
          this.doneLoading(Timeline.ProjectType)) {

        this.shouldLoadPlanningElements = function () { return false; };

        return true;
      }
      return false;
    };

    TimelineLoader.prototype.shouldLoadRemainingPlanningElements = function (lastLoaded) {

      if (this.doneLoading(Timeline.Project) &&
          this.doneLoading(Timeline.Reporting) &&
          this.doneLoading(Timeline.ProjectType) &&
          this.doneLoading(Timeline.PlanningElement)) {

        this.shouldLoadRemainingPlanningElements = function () { return false; };

        return true;
      }
      return false;
    };

    TimelineLoader.prototype.checkDependencies = function (identifier) {
      if (this.shouldLoadReportings(identifier)) {
        this.registerProjects(this.getRelevantProjectIdsBasedOnReportings());
      }
      else if (this.shouldLoadPlanningElements(identifier)) {
        this.data = this.dataEnhancer.enhance(this.data);

        this.registerPlanningElements(this.getRelevantProjectIdsBasedOnProjects());
      } else if (this.shouldLoadRemainingPlanningElements(identifier)) {
        this.registerPlanningElementsByID(this.getRemainingPlanningElements());
      }

      this.loader.load();
    };

    TimelineLoader.prototype.complete = function (data) {
      // This function is just a placeholder to let you know, that you should
      // probably register an event handler on 'complete'. The handler should
      // have the following signature:
      //
      //   function (e, data) {}
      return data;
    };

    return TimelineLoader;
  })(),


  checkPrerequisites: function() {
    if (jQuery === undefined) {
      throw new Error('jQuery seems to be missing (jQuery is undefined)');
    } else if (jQuery().slider === undefined) {
      throw new Error('jQuery UI seems to be missing (jQuery().slider is undefined)');
    } else if ((1).month === undefined) {
      throw new Error('date.js seems to be missing ((1).month is undefined)');
    } else if (Raphael === undefined) {
      throw new Error('Raphael seems to be missing (Raphael is undefined)');
    } else if (Raphael.fonts === undefined) {
      throw new Error('There seems to be a font missing (Raphael.fonts is undefined)');
    }
    return true;
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

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Data Store                                                        │
  // ├───────────────────────────────────────────────────────────────────┤
  // │ Model Prototypes:                                                 │
  // │ Timeline.PlanningElement                                          │
  // │ Timeline.ProjectType                                              │
  // │ Timeline.Project                                                  │
  // │ Timeline.Color                                                    │
  // │ Timeline.Reporting                                                │
  // ╰───────────────────────────────────────────────────────────────────╯
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
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.ProjectAssociation                                       │
  // ╰───────────────────────────────────────────────────────────────────╯

  ProjectAssociation: {
    identifier: 'project_associations',
    all: function(timeline) {
      // collect all project associations.
      var r = timeline.project_associations;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    },
    getOrigin: function() {
      return this.origin;
    },
    getTarget: function() {
      return this.project;
    },
    getOther: function(project) {
      var origin = this.getOrigin();
      var target = this.getTarget();
      if (project.id === origin.id) {
        return target;
      } else if (project.id === target.id) {
        return origin;
      }
      return null;
    },
    getInvolvedProjects: function() {
      return [this.getOrigin(), this.getTarget()];
    },
    involves: function(project) {
      var inv = this.getInvolvedProjects();

      return (
        project !== undefined &&
        inv[0] !== undefined &&
        inv[1] !== undefined &&
        (project.id === inv[0].id || project.id === inv[1].id)
      );
    }
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.Reporting                                                │
  // ╰───────────────────────────────────────────────────────────────────╯

  Reporting: {
    identifier: 'reportings',
    all: function(timeline) {
      // collect all reportings.
      var r = timeline.reportings;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    },
    getProject: function() {
      return (this.project !== undefined) ? this.project : null;
    },
    getProjectId: function () {
      return this.project.id;
    },
    getReportingToProject : function () {
      return (this.reporting_to_project !== undefined) ? this.reporting_to_project : null;
    },
    getReportingToProjectId : function () {
      return this.reporting_to_project.id;
    },
    getStatus: function() {
      return (this.reported_project_status !== undefined) ? this.reported_project_status : null;
    }
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.ProjectType                                              │
  // ╰───────────────────────────────────────────────────────────────────╯

  ProjectType: {
    identifier: 'project_types',
    all: function(timeline) {
      // collect all project types
      var r = timeline.project_types;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    }
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.Color                                                    │
  // ╰───────────────────────────────────────────────────────────────────╯

  Color: {
    identifier: 'colors',
    all: function(timeline) {
      // collect all colors
      var r = timeline.colors;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    }
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.PlanningElementType                                      │
  // ╰───────────────────────────────────────────────────────────────────╯

  PlanningElementType: {
    identifier: 'planning_element_types',
    all: function(timeline) {
      // collect all reportings.
      var r = timeline.planning_element_types;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    }
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.Project                                                  │
  // ╰───────────────────────────────────────────────────────────────────╯

  Project: {
    is: function(t) {
      return Timeline.Project.identifier === t.identifier;
    },
    identifier: 'projects',
    hide: function () {
      var hidden =  this.hiddenForEmpty() ||
                    this.hiddenForTimeFrame();

      this.hide = function () { return hidden; };

      return hidden;
    },
    hiddenForEmpty: function () {
      if (this.timeline.options.exclude_empty !== 'yes') {
        return false;
      }

      var hidden = true;
      // iterates over projects for second level grouping adjustments.
      // TODO simply hiding parents might be sufficient.
      jQuery.each(this.getPlanningElements(), function (i, child) {
        if (!child.filteredOut()) {
          hidden = false;
        }
      });

      return hidden;
    },
    hiddenForTimeFrame: function () {
      var types = this.timeline.options.planning_element_time_types;
      if (!types) {
        return false;
      }

      var hidden = true;

      //we need to look at every element
      jQuery.each(this.getPlanningElements(), function (i, child) {
        //if hidden is already false, do not calculate
        //otherwise, we show this project current element is a planning element (redundant?)
        //and it is inside our timeframe
        //and it has got the planning element type we want
        if (hidden &&
              child.is(Timeline.PlanningElement) &&
              child.inTimeFrame() &&
              Timeline.idInArray(types, child.getPlanningElementType())) {
                hidden = false;
        }
      });

      return hidden;
    },
    filteredOut: function() {
      var filtered = this.filteredOutForExclusionOfOwnPlanningElements() ||
                     this.filteredOutForExclusionOfReporters() ||
                     this.filteredOutForTypes() ||
                     this.filteredOutForStatus() ||
                     this.filteredOutForSubproject() ||
                     this.filteredOutForResponsibles();

      this.filteredOut = function () { return filtered; };

      return filtered;
    },
    filteredOutForExclusionOfOwnPlanningElements: function () {
      return (this.timeline.options.exclude_own_planning_elements === 'yes' &&
              (this.id === this.timeline.options.project_id ||
               this.identifier === this.timeline.options.project_id));
    },
    filteredOutForExclusionOfReporters: function() {
      return (this.timeline.options.exclude_reporters === 'yes' &&
              !(this.id === this.timeline.options.project_id ||
                this.identifier === this.timeline.options.project_id));
    },
    filteredOutForSubproject: function() {
      var i, j, p;
      var allowedParents = this.timeline.options.parents;

      if ((allowedParents === undefined) ||
          (allowedParents.length === 0)) {

        // if there is no filter, do not filter out anything.
        return false;

      } else {

        // for every id selected in the filter
        for (i = 0; i < allowedParents.length; i++) {

          j = Timeline.pnum(allowedParents[i]);

          if (j === -1) {
            // if the current selection is the (none) selection, we only need to
            // check the project's immediate parent. If it has none, it should
            // be shown, thus *not* filtered.
            if (this.parent === undefined) {
              return false;
            }
          }
          else {
            // if this project or one of it's ancestors has an id that is
            // equal to the current selection, it should be shown, thus *not*
            // filtered.
            p = this;
            while (p !== undefined) {
              if (p.id === j) {
                return false;
              } else {
                p = p.parent;
              }
            }
          }

        }

        // everything that was not decided to be *not* filtered until now should
        // be filtered.
        return true;
      }
    },
    filteredOutForResponsibles: function() {
      return Timeline.filterOutBasedOnArray(
        this.timeline.options.project_responsibles,
        this.getResponsible()
      );
    },
    filteredOutForStatus: function() {
      return Timeline.filterOutBasedOnArray(
        this.timeline.options.project_status,
        this.getProjectStatus()
      );
    },
    filteredOutForTypes: function() {
      return Timeline.filterOutBasedOnArray(this.timeline.options.project_types,
                                            this.getProjectType());
    },
    getPlanningElementType: function() {
      return undefined;
    },
    getPlanningElements: function() {
      if (!this.planning_elements) {
        return [];
      }
      if (!this.sorted_pes) {
        this.sort('planning_elements');
        this.sorted_pes = true;
      }
      return this.planning_elements;
    },
    getFirstLevelGroupingData: function() {
      return this.timeline.getGroupForProject(this);
    },
    getFirstLevelGrouping: function() {
      return this.timeline.getGroupForProject(this).number;
    },
    getFirstLevelGroupingName: function() {
      return this.timeline.getGroupForProject(this).name;
    },
    sort: function(field) {
      var timeline = this.timeline;
      this[field] = this[field].sort(function(a, b) {

        // order by inverse grouping, date, name, id
        var dc = 0, nc = 0;
        var as = a.start(), bs = b.start();
        var ag, bg;
        if (a.is(Timeline.Project) && b.is(Timeline.Project)) {
          var dataAGrouping = a.getFirstLevelGroupingData();
          var dataBGrouping = b.getFirstLevelGroupingData();

          // order first level grouping.
          if (dataAGrouping.id != dataBGrouping.id) {
            /** other is always at bottom */
            if (dataAGrouping.id == 0) {
              return 1;
            } else if (dataBGrouping.id == 0) {
              return -1;
            }

            if (timeline.options.grouping_one_sort == 1) {
              ag = dataAGrouping.number;
              bg = dataBGrouping.number;
            } else {
              ag = dataAGrouping.p.name;
              bg = dataBGrouping.p.name;
            }

            if (ag > bg) {
              return 1;
            }

            return -1;
          }
        }

        if (!as && typeof a.end === "function") {
          as = a.end();
        }
        if (!bs && typeof b.end === "function") {
          bs = b.end();
        }

        if (as) {
          if (bs) {
            dc = as.compareTo(bs);
          } else {
            dc = 1;
          }
        } else if (bs) {
          dc = -1;
        }

        if (!a.nameLower) {
          a.nameLower = a.name.toLowerCase();
        }

        if (!b.nameLower) {
          b.nameLower = b.name.toLowerCase();
        }

        if (a.nameLower < b.nameLower) {
          nc = -1;
        }
        if (a.nameLower > b.nameLower) {
          nc = +1;
        }

        if (a.hasSecondLevelGroupingAdjustment && b.hasSecondLevelGroupingAdjustment) {
          if (timeline.options.grouping_two_sort == 1) {
            if (dc !== 0) {
              return dc;
            }

            if (nc !== 0) {
              return nc;
            }
          } else if (timeline.options.grouping_two_sort == 2) {
            if (nc !== 0) {
              return nc;
            }

            if (dc !== 0) {
              return dc;
            }
          }
        }

        if (timeline.options.project_sort == 1 && a.is(Timeline.Project) && b.is(Timeline.Project)) {
          if (nc !== 0) {
            return nc;
          }

          if (dc !== 0) {
            return dc;
          }
        } else {
          if (dc !== 0) {
            return dc;
          }

          if (nc !== 0) {
            return nc;
          }
        }

        if (a.id > b.id) {
          return +1;
        } else if (a.id < b.id) {
          return -1;
        }
        return 0;
      });
      return this;
    },
    start: function() {
      var first = this.getPlanningElements()[0];
      if (!first) {
        return undefined;
      }
      return first.start();
    },
    getReporters: function() {
      if (!this.reporters) {
        return [];
      }
      if (!this.sorted_reps) {
        this.sort('reporters');
        this.sorted_reps = true;
      }
      return this.reporters;
    },
    addReporter: function(rep) {
      var reps = this.getReporters();
      if (jQuery.inArray(rep, reps) === -1) {
        reps.push(rep);
        this.reporters = reps;
        this.sorted_reps = false;
        return true;
      }
      return false;
    },
    removeReporter: function(rep) {
      // this fails silently, when reporter to be removed is not in the list reporters.
      var new_reporters = jQuery.grep(this.getReporters(), function(e, i) {
          return e.id !== rep.id;
        });
      this.reporters = new_reporters;
      // we are not resetting sorted_reps, since removal does not affect sortation.
    },
    getProjectStatus: function() {
      return this.via_reporting !== undefined ? this.via_reporting.getStatus() : null;
    },
    getProjectType: function() {
      return (this.project_type !== undefined) ? this.project_type : null;
    },
    getResponsible: function() {
      return (this.responsible !== undefined) ? this.responsible : null;
    },
    getSubElements: function() {
      var result = [];

      jQuery.each(this.getPlanningElements(), function(i, e) {
        // filtering of planning elements now happens in iterateWithChildren
        result.push(e);
      });

      jQuery.each(this.getReporters(), function(i, e) {
        // filtering of projects still happens here.
        if (!e.filteredOut()) {
          result.push(e);
        }
      });

      return result;
    },
    getParent: function() {
      var parent;
      if(!this.parent) return null;
      parent = this.timeline.getProject(this.parent.id);

      this.parent = parent;
      this.getParent = function() { return this.parent; };

      return this.getParent();
    },
    getUrl: function() {
      var options = this.timeline.options;
      var url = options.url_prefix;

      url += options.project_prefix;
      url += "/";
      url += this.identifier;
      url += "/timelines";

      return url;
    },
    render: function(node) {
      if (node.isExpanded()) {
        return false;
      }

      var timeline = this.timeline;
      var scale = timeline.getScale();
      var beginning = timeline.getBeginning();
      var milestones, others;

      // draw all planning elements that should be seen in an
      // aggregation. limited to one level.

      var pes = this.getPlanningElements();

      var dummy_node = {
        getDOMElement: function() {
          return node.getDOMElement();
        },
        isExpanded: function() {
          return false;
        }
      };

      var is_milestone = function(e, i) {
        var pet = e.getPlanningElementType();
        return pet && pet.is_milestone;
      };

      var render = function(i, e) {
        var node = jQuery.extend({}, dummy_node, {
          getData: function() { return e; }
        });
        e.render(node, true, label_spaces[i]);
        e.renderForeground(node, true, label_spaces[i]);
      };

      var visible_in_aggregation = function(e, i) {
        var pet = e.getPlanningElementType();
        return !e.filteredOut() && pet && pet.in_aggregation;
      };

      // The label_spaces object will contain available spaces per
      // planning element. There may be many.
      var label_spaces = {};

      // divide into milestones and others.
      milestones = jQuery.grep(pes, is_milestone);
      others = jQuery.grep(pes, is_milestone, true);

      // join others with milestones, and remove all that should be filtered.
      pes = jQuery.grep(others.concat(milestones), visible_in_aggregation);

      // Outer loop to calculate best label space for each planning
      // element. Here, we initialize possible spaces by registering the
      // whole element as the single space for a label.
      jQuery.each(pes, function(i, e) {
        var b = e.getHorizontalBounds(scale, beginning);
        label_spaces[i] = [b];

        // Now, for every other element (that is above the one we're
        // traversing), shorten the available spaces or splice them.
        jQuery.each(pes, function(j, f) {
          var k, cb = f.getHorizontalBounds(scale, beginning, is_milestone(f));

          // do not shorten if I am looking at myself.
          if (e === f) {
            return;
          }

          // do not shorten if current element is not a milestone and
          // begins before me.
          if (!is_milestone(f) && cb.x < b.x) {
            return;
          }

          // do not shorten if both are milestones and current begins before me.
          if (is_milestone(f) && is_milestone(e) && cb.x < b.x) {
            return;
          }

          // do not shorten if I am a milestone and current element is not.
          if (is_milestone(e) && !is_milestone(f)) {
            return;
          }

          if (!e.hasBothDates() || !f.hasBothDates()) {
            return;
          }

          // iterate over actual spaces left for shortening or splicing.
          var spaces = label_spaces[i];
          for (k = 0; k < spaces.length; k++) {
            var space = spaces[k];
            // b  eeeeeeee
            //cb       fffffffffff

            // current element lies after me,
            var rightSideOverlap = cb.x > space.x &&
                    // but I do end after its start.
                    cb.x < space.end();
            // b           eeeeeeeeeee
            //cb    ffffffffffff

            // current element lies before me
            var leftSideOverlap = cb.end() < space.end() &&
                      // but I start before current elements end.
                      cb.end() > space.x;

            if ((cb.x < space.x && cb.end() > space.end()) &&
                (label_spaces[i].length > 0)) {
              if (label_spaces[i].length === 1) {
                label_spaces[i][0].w = 0;
              } else {
                label_spaces[i].splice(k, 1);
              }
            }

            //  fffffffeeeeeeeeeeeeffffffffff
            if (rightSideOverlap && leftSideOverlap) {

              // if current planning element is completely enclosed
              // in the current space, split the space into two, and
              // reiterate. splitting happens by splicing the array at
              // position i.
              label_spaces[i].splice(k, 1,
                {'x': space.x,
                 'w': cb.x - space.x, end: space.end},
                {'x': cb.end(),
                 'w': space.end() - cb.end(), end: space.end});


            } else if (rightSideOverlap) {

              // if current planning element (f) starts before the one
              // current space ends, adjust the width of the space.
              space.w = Math.min(space.end(), cb.x) - space.x;

            } else if (leftSideOverlap) {

              // if current planning element (f) ends after the current
              // space starts, adjust the beginning of the space.
              // we also need to modify the width because we want to
              // keep the end at the same position.
              var oldStart = space.x;
              space.x = Math.max(space.x, cb.end());
              space.w -= (space.x - oldStart);
            }
          }
        });

        // after all possible label spaces for the given element are
        // evaluated, select the widest.
        b = label_spaces[i].shift();
        jQuery.each(label_spaces[i], function(i, e) {
          if (e.w > b.w) {
            b = e;
          }
        });
        label_spaces[i] = b;
      });

      // jQuery.each(others, render);
      // jQuery.each(milestones, render);
      jQuery.each(pes, render);
    },
    getElements: function() {
      return [];
    },
    all: function(timeline) {
      // collect all planning elements
      var r = timeline.projects;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    }
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.HistoricalPlanningElement                                │
  // ╰───────────────────────────────────────────────────────────────────╯

  HistoricalPlanningElement: {
    identifier: 'historical_planning_elements'
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Timeline.PlanningElement                                          │
  // ╰───────────────────────────────────────────────────────────────────╯

  PlanningElement: {
    is: function(t) {
      return Timeline.PlanningElement.identifier === t.identifier;
    },
    identifier: 'planning_elements',
    hide: function () {
      return false;
    },
    filteredOut: function() {
      var filtered = this.filteredOutForProjectFilter() ||
                     this.filteredOutForPlanningElementTypes() ||
                     this.filteredOutForResponsibles();

      this.filteredOut = function() { return filtered; };

      return filtered;
    },
    inTimeFrame: function () {
      return this.timeline.inTimeFilter(this.start(), this.end());
    },
    filteredOutForProjectFilter: function() {
      return this.project.filteredOut();
    },
    filteredOutForResponsibles: function() {
      return Timeline.filterOutBasedOnArray(
        this.timeline.options.planning_element_responsibles,
        this.getResponsible()
      );
    },
    filteredOutForPlanningElementTypes: function() {
      return Timeline.filterOutBasedOnArray(
        this.timeline.options.planning_element_types,
        this.getPlanningElementType()
      );
    },
    all: function(timeline) {
      // collect all planning elements
      var r = timeline.planning_elements;
      var result = [];
      for (var key in r) {
        if (r.hasOwnProperty(key)) {
          result.push(r[key]);
        }
      }
      return result;
    },
    getProject: function() {
      return (this.project !== undefined) ? this.project : null;
    },
    getPlanningElementType: function() {
      return (this.planning_element_type !== undefined) ?
        this.planning_element_type : null;
    },
    getResponsible: function() {
      return (this.responsible !== undefined) ? this.responsible : null;
    },
    getParent: function() {
      return (this.parent !== undefined) ? this.parent : null;
    },
    getChildren: function() {
      if (!this.planning_elements) {
        return [];
      }
      if (!this.sorted) {
        this.sort('planning_elements');
        this.sorted = true;
      }
      return this.planning_elements;
    },
    hasChildren: function() {
      return this.getChildren().length > 0;
    },
    sort: function(field) {
      this[field] = this[field].sort(function(a, b) {
        // order by date, name
        var dc = 0;
        var as = a.start(), bs = b.start();
        if (as) {
          if (bs) {
            dc = as.compareTo(bs);
          } else {
            dc = 1;
          }
        } else if (bs) {
          dc = -1;
        }
        if (dc !== 0) {
          return dc;
        }
        if (a.name < b.name) {
          return -1;
        }
        if (a.name > b.name) {
          return +1;
        }
        return 0;
      });
      return this;
    },
    start: function() {
      var pet = this.getPlanningElementType();
      //if we have got a milestone w/o a start date but with an end date, just set them the same.
      if (this.start_date === undefined && this.end_date !== undefined && pet && pet.is_milestone) {
        this.start_date = this.end_date;
      }
      if (this.start_date_object === undefined && this.start_date !== undefined) {
        this.start_date_object = Date.parse(this.start_date);
      }
      return this.start_date_object;
    },
    end: function() {
      var pet = this.getPlanningElementType();
      //if we have got a milestone w/o a start date but with an end date, just set them the same.
      if (this.end_date === undefined && this.start_date !== undefined && pet && pet.is_milestone) {
        this.end_date = this.start_date;
      }
      if (this.end_date_object=== undefined && this.end_date !== undefined) {
        this.end_date_object = Date.parse(this.end_date);
      }
      return this.end_date_object;
    },
    alternate_start: function() {
      if (this.alternate_start_date_object === undefined) {
        this.alternate_start_date_object = Date.parse(this.alternate_start_date);
      }
      return this.alternate_start_date_object;
    },
    alternate_end: function() {
      if (this.alternate_end_date_object=== undefined) {
        this.alternate_end_date_object = Date.parse(this.alternate_end_date);
      }
      return this.alternate_end_date_object;
    },
    getSubElements: function() {
      return this.getChildren();
    },
    hasAlternateDates: function() {
      return (this.alternate_start_date !== undefined &&
              this.alternate_end_date !== undefined &&
              (!(this.start_date === this.alternate_start_date &&
                 this.end_date === this.alternate_end_date)) ||
              this.is_deleted);
    },
    isDeleted: function() {
      return true && this.is_deleted;
    },
    isNewlyAdded: function() {
      return (this.timeline.isComparing() &&
              this.alternate_start_date === undefined &&
              this.alternate_end_date === undefined);
    },
    getAlternateHorizontalBounds: function(scale, absolute_beginning, milestone) {
      return this.getHorizontalBoundsForDates(
        scale,
        absolute_beginning,
        this.alternate_start(),
        this.alternate_end(),
        milestone
      );
    },
    getHorizontalBounds: function(scale, absolute_beginning, milestone) {
      return this.getHorizontalBoundsForDates(
        scale,
        absolute_beginning,
        this.start(),
        this.end(),
        milestone
      );
    },
    hasStartDate: function () {
      if (this.start()) {
        return true;
      }

      return false;
    },
    hasEndDate: function () {
      if (this.end()) {
        return true;
      }

      return false;
    },
    hasBothDates: function () {
      if (this.start() && this.end()) {
        return true;
      }

      return false;
    },
    hasOneDate: function () {
      if (this.start() || this.end()) {
        return true;
      }

      return false;
    },
    getHorizontalBoundsForDates: function(scale, absolute_beginning, start, end, milestone) {
      var timeline = this.timeline;

      if (!start && !end) {
        return {
          'x': 0,
          'w': 0,
          'end': function () {
            return this.x + this.w;
          }
        };
      } else if (!end) {
        end = start.clone().addDays(2);
      } else if (!start) {
        start = end.clone().addDays(-2);
      }

      // calculate graphical representation. the +1 makes sense when
      // considering equal start and end date.
      var x = timeline.getDaysBetween(absolute_beginning, start) * scale.day;
      var w = (timeline.getDaysBetween(start, end) + 1) * scale.day;

      if (milestone === true) {
        //we are in the middle of the diamond so we have to move half the size to the left
        x -= ((scale.height - 1) / 2);
        //and add the diamonds corners to the width.
        w += scale.height - 1;
      }

      return {
        'x': x,
        'w': w,
        'end': function () {
          return this.x + this.w;
        }
      };
    },
    getUrl: function() {
      var options = this.timeline.options;
      var url = options.url_prefix;

      url += "/work_packages/";
      url += this.id;

      return url;
    },
    getColor: function () {
      // if there is a color for this planning element type, use it.
      // use it also for planning elements w/ children. if there are
      // children but no planning element type, use the default color
      // for planning element parents. if there is no planning element
      // type and there are no children, use a default color.
      var pet = this.getPlanningElementType();
      var color;

      if (pet && pet.color) {
        color = pet.color.hexcode;
      } else if (this.hasChildren()) {
        color = Timeline.DEFAULT_PARENT_COLOR;
      } else {
        color = Timeline.DEFAULT_COLOR;
      }

      if (!this.hasBothDates()) {
        if (this.hasStartDate()) {
          color = "180-#ffffff-" + color;
        } else {
          color = "180-" + color + "-#ffffff";
        }
      }

      return color;
    },
    render: function(node, in_aggregation, label_space) {
      var timeline = this.timeline;
      var paper = timeline.getPaper();
      var scale = timeline.getScale();
      var beginning = timeline.getBeginning();
      var elements = [];
      var pet = this.getPlanningElementType();
      var self = this;
      var color, text, x, y, textColor;
      var bounds = this.getHorizontalBounds(scale, beginning);
      var left = bounds.x;
      var width = bounds.w;
      var alternate_bounds = this.getAlternateHorizontalBounds(scale, beginning);
      var alternate_left = alternate_bounds.x;
      var alternate_width = alternate_bounds.w;
      var hover_left = left;
      var hover_width = width;
      var element = node.getDOMElement();
      var captionElements = [];
      var label;
      var deleted = true && this.is_deleted;
      var comparison_offset = deleted ? 0 : Timeline.DEFAULT_COMPARISON_OFFSET;
      var strokeColor = Timeline.DEFAULT_STROKE_COLOR;

      var has_both_dates = this.hasBothDates();
      var has_one_date = this.hasOneDate();
      var has_start_date = this.hasStartDate();

      if (in_aggregation) {
        hover_left = label_space.x + Timeline.HOVER_THRESHOLD;
        hover_width = label_space.w - 2 * Timeline.HOVER_THRESHOLD;
      }

      if (in_aggregation && !has_both_dates) {
        return;
      }

      var has_alternative = this.hasAlternateDates();
      var could_have_been_milestone = (this.alternate_start === this.alternate_end);

      var height, top;

      // only render planning elements that have
      // either a start or an end date.
      if (has_one_date) {
        color = this.getColor();


        if (!has_both_dates) {
          strokeColor = 'none';
        }

        // ╭─────────────────────────────────────────────────────────╮
        // │ Rendering of historical data. Use default planning      │
        // │ element appearance, only use milestones when the        │
        // │ element is currently a milestone and the historical     │
        // │ data has equal start and end dates.                     │
        // ╰─────────────────────────────────────────────────────────╯

        //TODO: fix for work units w/o start/end date
        if (!in_aggregation && has_alternative) {
          if (pet && pet.is_milestone && could_have_been_milestone) {

            height = scale.height - 1; //6px makes the element a little smaller.
            top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

            paper.path(
              timeline.psub('M#{x} #{y}h#{w}l#{d} #{d}l-#{d} #{d}H#{x}l-#{d} -#{d}l#{d} -#{d}Z', {
                x: alternate_left + scale.day / 2,
                y: top - comparison_offset,
                w: alternate_width - scale.day,
                d: height / 2 // diamond corner width.
              })
            ).attr({
              'fill': color, // Timeline.DEFAULT_FILL_COLOR_IN_COMPARISONS,
              'opacity': 0.33,
              'stroke': Timeline.DEFAULT_STROKE_COLOR_IN_COMPARISONS,
              'stroke-dasharray': Timeline.DEFAULT_STROKE_DASHARRAY_IN_COMPARISONS
            });

          } else {

            height = scale.height - 6; //6px makes the element a little smaller.
            top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

            paper.rect(
              alternate_left,
              top - comparison_offset, // 8px margin-top
              alternate_width,
              height,           // 8px  margin-bottom
              4                           // round corners
            ).attr({
              'fill': color, // Timeline.DEFAULT_FILL_COLOR_IN_COMPARISONS,
              'opacity': 0.33,
              'stroke': Timeline.DEFAULT_STROKE_COLOR_IN_COMPARISONS,
              'stroke-dasharray': Timeline.DEFAULT_STROKE_DASHARRAY_IN_COMPARISONS
            });
          }
        }

        // ╭─────────────────────────────────────────────────────────╮
        // │ Rendering of actual elements, as milestones, with teeth │
        // │ and the generic, dafault planning element w/ round      │
        // │ edges.                                                  │
        // ╰─────────────────────────────────────────────────────────╯

        // in_aggregation defines whether the planning element should be
        // renderd as a generic planning element regardless of children.

        if (!deleted && pet && pet.is_milestone) {

        } else if (!deleted && !in_aggregation && this.hasChildren() && node.isExpanded()) {

          // with teeth (has children).

          paper.path(
            timeline.psub('M#{x} #{y}m#{d} #{d}l-#{d} #{d}l-#{d} -#{d}V#{y}H#{x}h#{w}h#{d}v#{d}l-#{d} #{d}l-#{d} -#{d}z' + /* outer path */
                          'm0 0v-#{d}m#{w} 0m-#{d} 0m-#{d} 0v#{d}' /* inner vertical lines */, {
              x: left,
              y: timeline.getRelativeVerticalOffset(element) + 8,
              d: scale.height + 2 - 16,
              w: width
            })
          ).attr({
            'fill': color,
            'stroke': strokeColor
          });
        } else if (!deleted) {

          // generic.

          height = scale.height - 6; //6px makes the element a little smaller.
          top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

          paper.rect(
            left,
            top,
            width,
            height,
            4                           // round corners
          ).attr({
            'fill': color,
            'stroke': strokeColor
          });
        }
      }
    },
    renderForeground: function (node, in_aggregation, label_space) {
      var timeline = this.timeline;
      var paper = timeline.getPaper();
      var scale = timeline.getScale();
      var beginning = timeline.getBeginning();
      var elements = [];
      var pet = this.getPlanningElementType();
      var self = this;
      var color, text, x, y, textColor;
      var bounds = this.getHorizontalBounds(scale, beginning);
      var left = bounds.x;
      var width = bounds.w;
      var alternate_bounds = this.getAlternateHorizontalBounds(scale, beginning);
      var alternate_left = alternate_bounds.x;
      var alternate_width = alternate_bounds.w;
      var hover_left = left;
      var hover_width = width;
      var element = node.getDOMElement();
      var captionElements = [];
      var label;
      var deleted = true && this.is_deleted;
      var comparison_offset = deleted ? 0 : Timeline.DEFAULT_COMPARISON_OFFSET;

      var has_both_dates = this.hasBothDates();
      var has_one_date = this.hasOneDate();
      var has_start_date = this.hasStartDate();

      if (in_aggregation) {
        hover_left = label_space.x + Timeline.HOVER_THRESHOLD;
        hover_width = label_space.w - 2 * Timeline.HOVER_THRESHOLD;
      }

      var has_alternative = this.hasAlternateDates();
      var could_have_been_milestone = (this.alternate_start === this.alternate_end);

      var height, top;

      // if there is a color for this planning element type, use it.
      // use it also for planning elements w/ children. if there are
      // children but no planning element type, use the default color
      // for planning element parents. if there is no planning element
      // type and there are no children, use a default color.

      if (pet && pet.color) {
        color = pet.color.hexcode;
      } else if (this.hasChildren()) {
        color = Timeline.DEFAULT_PARENT_COLOR;
      } else {
        color = Timeline.DEFAULT_COLOR;
      }

      if (!deleted && pet && pet.is_milestone) {

        // milestones.
        height = scale.height - 1; //6px makes the element a little smaller.
        top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

        paper.path(
          timeline.psub('M#{x} #{y}h#{w}l#{d} #{d}l-#{d} #{d}H#{x}l-#{d} -#{d}l#{d} -#{d}Z', {
            x: left + scale.day / 2,
            y: top,
            w: width - scale.day,
            d: height / 2 // diamond corner width.
          })
        ).attr({
          'fill': color,
          'stroke': Timeline.DEFAULT_STROKE_COLOR
        });

      }



      // ╭─────────────────────────────────────────────────────────╮
      // │ Labels for rendered elements, eigther in aggregartion   │
      // │ or out of aggregation, inside of elements or outside.   │
      // ╰─────────────────────────────────────────────────────────╯

      height = scale.height - 6; //6px makes the element a little smaller.
      top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

      y = top + 11;

      if (has_one_date) {
        if (!in_aggregation) {

          // text rendering in planning elements outside of aggregations
          text = timeline.getMeasuredPathFromText(this.name);

          // if this is an expanded planning element w/ children, or if
          // the text would not fit:
          if (this.hasChildren() && node.isExpanded() ||
              text.progress * Timeline.PE_TEXT_SCALE > width - Timeline.PE_TEXT_INSIDE_PADDING) {

            // place a white rect below the label.
            captionElements.push(
              timeline.paper.rect(
                -16,
                -64,
                text.progress + 32,
                80,
                24
              ).attr({
                'fill': '#ffffff',
                'opacity': 0.5,
                'stroke': 'none'
              }));


            // text outside planning element
            x = left + width + Timeline.PE_TEXT_OUTSIDE_PADDING;
            textColor = Timeline.PE_DEFAULT_TEXT_COLOR;

            if (this.hasChildren()) {
              x += Timeline.PE_TEXT_ADDITIONAL_OUTSIDE_PADDING_WHEN_EXPANDED_WITH_CHILDREN;
            }

            if (pet && pet.is_milestone) {
              x += Timeline.PE_TEXT_ADDITIONAL_OUTSIDE_PADDING_WHEN_MILESTONE;
            }

          } else if (!has_both_dates) {
            // text inside planning element
            if (has_start_date) {
              x = left + 4;                                // left of the WU
            } else {
              x = left + width -                           // right of the WU
                text.progress * Timeline.PE_TEXT_SCALE -   // text width
                4;                                         // small border from the right
            }

            textColor = timeline.getLimunanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
              Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;
          } else {

            // text inside planning element
            x = left + width * 0.5 +                             // center of the planning element
                text.progress * Timeline.PE_TEXT_SCALE * (-0.5); // half of text width

            textColor = timeline.getLimunanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
              Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;
          }

          label = timeline.paper.path(text.path);
          captionElements.push(label);

          label.attr({
            'fill': textColor,
            'stroke': 'none'
          });

          jQuery.each(captionElements, function(i, e) {
            e.translate(x, y).scale(Timeline.PE_TEXT_SCALE, Timeline.PE_TEXT_SCALE, 0, 0);
          });

        } else if (true) {

          // the other case is text rendering in planning elements inside
          // of aggregations:

          text = timeline.getMeasuredPathFromText(this.name,
                     (label_space.w - Timeline.PE_TEXT_INSIDE_PADDING) / Timeline.PE_TEXT_SCALE);
          label = timeline.paper.path(text.path);
          captionElements.push(label);

          x = label_space.x + label_space.w * 0.5 +            // center of the planning element
              text.progress * Timeline.PE_TEXT_SCALE * (-0.5); // half of text width

          textColor = timeline.getLimunanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
                      Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;

          label.attr({
            'fill': textColor,
            'stroke': 'none'
          });

          jQuery.each(captionElements, function(i, e) {
            e.translate(x, y).scale(Timeline.PE_TEXT_SCALE, Timeline.PE_TEXT_SCALE, 0, 0);
          });
        }
      }

      // ╭─────────────────────────────────────────────────────────╮
      // │ Defining hover areas that will produce tooltips when    │
      // │ mouse is over them. This is last to include text drawn  │
      // │ over planning elements.                                 │
      // ╰─────────────────────────────────────────────────────────╯

      height = scale.height - 6; //6px makes the element a little smaller.
      top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

      elements.push(paper.rect(
        hover_left - Timeline.HOVER_THRESHOLD,
        top - Timeline.HOVER_THRESHOLD, // 8px margin-top
        hover_width + 2 * Timeline.HOVER_THRESHOLD,
        height + 2 * Timeline.HOVER_THRESHOLD,           // 8px margin-bottom
        4                           // round corners
      ).attr({
        'fill': '#ffffff',
        'opacity': 0
      }));

      jQuery.each(elements, function(i, e) {
        timeline.addHoverHandler(node, e);
        //self.addElement(e);
      });
    },
    renderVertical: function(node) {
      var timeline = this.timeline;
      var paper = timeline.getPaper();
      var scale = timeline.getScale();
      var beginning = timeline.getBeginning();

      var pet = this.getPlanningElementType();
      var self = this;
      var color;
      var bounds = this.getHorizontalBounds(scale, beginning);

      var deleted = true && this.is_deleted;

      var left = bounds.x;
      var width = bounds.w;

      var element = node.getDOMElement();

      var has_both_dates = this.hasBothDates();
      var has_one_date = this.hasOneDate();
      var has_start_date = this.hasStartDate();

      color = this.getColor();

      if (has_one_date) {
        if (!deleted && pet && pet.is_milestone) {
          timeline.paper.path(
            timeline.psub("M#{left} #{top}L#{left} #{height}", {
              'left': left + scale.day / 2,
              'top': timeline.decoHeight(),
              'height': timeline.getMeasuredHeight()
            })
          ).attr({
            'stroke': color,
            'stroke-width': 2,
            'stroke-dasharray': '- '
          });

          var hoverElement = paper.rect(
            left + scale.day / 2 - 2 * Timeline.HOVER_THRESHOLD,
            timeline.decoHeight(), // 8px margin-top
            4 * Timeline.HOVER_THRESHOLD,
            timeline.getMeasuredHeight()           // 8px margin-bottom
          ).attr({
            'fill': '#ffffff',
            'opacity': 0
          });

          timeline.addHoverHandler(node, hoverElement);
        } else if (!deleted) {
          paper.rect(
            left,
            timeline.decoHeight(),
            width,
            timeline.getMeasuredHeight()
          ).attr({
            'fill': color,
            'stroke': Timeline.DEFAULT_STROKE_COLOR,
            'opacity': 0.2
          });

          var hoverElement = paper.rect(
            left - Timeline.HOVER_THRESHOLD,
            timeline.decoHeight(), // 8px margin-top
            width + 2 * Timeline.HOVER_THRESHOLD,
            timeline.getMeasuredHeight()           // 8px margin-bottom
          ).attr({
            'fill': '#ffffff',
            'opacity': 0
          });

          timeline.addHoverHandler(node, hoverElement);
          //self.addElement(hoverElement);
        }
      }
    },
    addElement: function(e) {
      if (!this.elements) {
        this.elements = [];
      }
      this.elements.push(e);
      return this;
    },
    getElements: function() {
      if (!this.elements) {
        this.elements = [];
      }
      return this.elements;
    }
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ Defaults and random accessors                                     │
  // ╰───────────────────────────────────────────────────────────────────╯

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
            'number': j,
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

  TreeNode: {

    payload: undefined,
    parentNode: undefined,
    childNodes: undefined,
    expanded: false,

    totalCount: 0,
    projectCount: 0,

    getData: function() {
      return this.payload;
    },
    setData: function(data) {
      this.payload = data;
      return this;
    },
    appendChild: function(node) {
      if (!this.childNodes) {
        this.childNodes = [node];
      } else {
        this.childNodes.push(node);
      }
      return node.parentNode = this;
    },
    removeChild: function(node) {
      var result;
      jQuery.each(this.childNodes, function(i, e) {
        if (node === e) {
          result = node;
        }
      });
      return result;
    },
    hasChildren: function() {
      return this.childNodes && this.childNodes.length > 0;
    },
    children: function() {
      return this.childNodes;
    },
    root: function() {
      if (this.parentNode) {
        return this.parentNode.root();
      } else {
        return this;
      }
    },
    isExpanded: function() {
      return this.expanded;
    },
    setExpand: function(state) {
      return this.expanded = state;
    },
    expand: function() {
      return this.setExpand(true);
    },
    collapse: function() {
      return this.setExpand(false);
    },
    toggle: function() {
      return this.setExpand(!this.expanded);
    },
    setExpandedAll: function(state) {
      if (!this.hasChildren()) {
        return;
      }
      this.setExpand(state);
      jQuery.each(this.children(), function(i, e) {
        e.setExpandedAll(state);
      });
    },
    expandAll: function() {
      return this.setExpandedAll(true);
    },
    collapseAll: function() {
      return this.setExpandedAll(false);
    },
    setDOMElement: function(element) {
      this.dom_element = element;
    },
    getDOMElement: function() {
      return this.dom_element;
    },
    iterateWithChildren: function(callback, options) {
      var root = this.root();
      var self = this;
      var timeline;
      var filtered_out, hidden;
      var children = this.children();
      var has_children = children !== undefined;

      // there might not be any payload, due to insufficient rights and
      // the fact that some user with more rights originally created the
      // report.
      if (root.payload === undefined) {
        // FLAG raise some flag indicating that something is
        // wrong/missing.
        return this;
      }

      timeline = root.payload.timeline;
      hidden = this.payload.hide();
      filtered_out = this.payload.filteredOut();
      options = options || {indent: 0, index: 0, projects: 0};

      // ╭─────────────────────────────────────────────────────────╮
      // │ The hide_other_group flag is an option that cuases      │
      // │ iteration to stop when the "other" group, i.e.,         │
      // │ everything that is not otherwise grouped, is reached.   │
      // │ This effectively hides that group.                      │
      // ╰─────────────────────────────────────────────────────────╯
      // the "other" group is reached when we are dealing with a
      // grouping timeline, the current payload is a project, not root,
      // but on level 0, and the first level grouping is 0.

      if (timeline.options.hide_other_group &&
          timeline.isGrouping() &&
          this.payload.is(Timeline.Project) &&
          this !== root &&
          options.indent === 0 &&
          this.payload.getFirstLevelGrouping() === 0) {

        return;
      }

      if (this === root) {
        options = jQuery.extend({}, {indent: 0, index: 0, projects: 0, traverseCollapsed: false}, options);
      }

      if (this === root && timeline.options.hide_tree_root === true) {

        // ╭───────────────────────────────────────────────────────╮
        // │ There used to be a requirement that disabled planning │
        // │ elements in root when root should be hidden. That     │
        // │ requirement was inverted and it is now desired to     │
        // │ show all such planning elements on the root level of  │
        // │ the tree.                                             │
        // ╰───────────────────────────────────────────────────────╯

        if (has_children) {
          jQuery.each(children, function(i, e) {
            e.iterateWithChildren(callback, options);
          });
        }

      } else {

        // ╭───────────────────────────────────────────────────────╮
        // │ There is a requirement that states that filter status │
        // │ should no longer be inherited. The callback therefore │
        // │ is only invoked when payload is not filtered out. The │
        // │ same is true for incrementing the projects and index  │
        // │ count.                                                │
        // ╰───────────────────────────────────────────────────────╯

        if (!filtered_out && !hidden) {

          if (callback) {
            callback.call(this, this, options.indent, options.index);
          }

          if (this.payload.is(Timeline.Project)) {
            options.projects++;
          }

          options.index++;
        }

        // ╭───────────────────────────────────────────────────────╮
        // │ There is a requirement that states that if the        │
        // │ current node is closed, children that are projects    │
        // │ should be displayed anyway, and only children that    │
        // │ are planning elements should be removed from the      │
        // │ view. Beware, this only works as long as there are no │
        // │ projects that are children of planning elements.      │
        // ╰───────────────────────────────────────────────────────╯

        // if there are children, loop over them, independently of
        // current node expansion state.
        if (has_children) {
          options.indent++;

          jQuery.each(children, function(i, child) {

            // ╭───────────────────────────────────────────────────╮
            // │ Now, if the node, the children of which we        │
            // │ are looping over, was expanded, iterate           │
            // │ over its children, recursively. Do the same       │
            // │ if the iteration was configured with the          │
            // │ traverseCollapsed flag. Last but not least, if    │
            // │ the current child is a project, iterate over it   │
            // │ only if indentation is not too deep.              │
            // ╰───────────────────────────────────────────────────╯

            if (options.traverseCollapsed ||
                self.isExpanded() ||
                child.payload.is(Timeline.Project)) {

                //do we wan to inherit the hidden status from projects to planning elements?
                if (!hidden || child.payload.is(Timeline.Project)) {
                  if (!(options.indent > 1 && child.payload.is(Timeline.Project))) {
                    child.iterateWithChildren(callback, options);
                  }
                }
            }
          });

          options.indent--;
        }
      }

      if (this === root) {
        this.totalCount = options.index;
        this.projectCount = options.projects;
      }
      return this;
    },

    // ╭───────────────────────────────────────────────────╮
    // │ The following methods are supposed to be called   │
    // │ from the root level of the tree, but do           │
    // │ gracefully retrieve the root if called from       │
    // │ anywhere else.                                    │
    // ╰───────────────────────────────────────────────────╯
    expandTo: function(level) {
      var root = this.root();
      var i = 0, expandables = [root];
      var expand = function (i,e) { return e.expand(); };
      var children;
      var j, c;

      if (level === undefined) {
        // "To infinity ... and beyond!" - Buzz Lightyear.
        level = Infinity;
      }

      // collapse all, and expand only as much as is enabled by default.
      root.collapseAll();

      while (i++ < level && expandables.length > 0) {

        jQuery.each(expandables, expand);
        children = [];
        for (j = 0; j < expandables.length; j++) {
          c = expandables[j].children();
          if (c) {
            children = children.concat(c);
          }
        }
        expandables = children;
      }

      return level;
    },
    numberOfProjects: function() {
      return this.getRootProperty('projectCount');
    },
    numberOfPlanningElements: function() {
      return this.getRootProperty('totalCount') -
        this.getRootProperty('projectCount');
    },
    height: function() {
      return this.getRootProperty('totalCount');
    },
    getRootProperty: function(property) {
      var root = this.root();
      this.iterateWithChildren();
      return root[property];
    },
    containsProjects: function() {
      return this.numberOfProjects() !== 0;
    },
    containsPlanningElements: function() {
      return this.numberOfPlanningElements() !== 0;
    }
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
  },

  // ╭───────────────────────────────────────────────────────────────────╮
  // │ UI and Plotting                                                   │
  // ╰───────────────────────────────────────────────────────────────────╯

  DEFAULT_COLOR: '#999999',
  DEFAULT_FILL_COLOR_IN_COMPARISONS: 'none',
  DEFAULT_LANE_COLOR: '#000000',
  DEFAULT_LANE_WIDTH: 1,
  DEFAULT_PARENT_COLOR: '#666666',
  DEFAULT_STROKE_COLOR: '#000000',
  DEFAULT_STROKE_COLOR_IN_COMPARISONS: '#000000',
  DEFAULT_STROKE_DASHARRAY_IN_COMPARISONS: '', // other examples: '-', '- ', '-- '
  DEFAULT_COMPARISON_OFFSET: 5,

  DAY_WIDTH: 16,

  MIN_CHART_WIDTH: 200,
  RENDER_BUCKETS: 2,
  ORIGINAL_BORDER_WIDTH_CORRECTION: 3,
  BORDER_WIDTH_CORRECTION: 3,
  HOVER_THRESHOLD: 3,

  GROUP_BAR_INDENT: -10,

  PE_DARK_TEXT_COLOR: '#000000',    // color on light planning element.
  PE_DEFAULT_TEXT_COLOR: '#000000', // color on timelines background.
  PE_HEIGHT: 20,
  PE_LIGHT_TEXT_COLOR: '#ffffff',   // color on dark planning element.
  PE_LUMINANCE_THRESHOLD: 0.5,      // threshold above which dark text is rendered.
  PE_TEXT_ADDITIONAL_OUTSIDE_PADDING_WHEN_MILESTONE: 6,
  PE_TEXT_ADDITIONAL_OUTSIDE_PADDING_WHEN_EXPANDED_WITH_CHILDREN: 6,
  PE_TEXT_INSIDE_PADDING: 8,        // 4px padding on both sides of the planning element towards an inside labelelement towards an inside label.
  PE_TEXT_OUTSIDE_PADDING: 6,       // space between planning element and text to its right.
  PE_TEXT_SCALE: 0.1875,            // 64 * (1/8 * 1.5) = 12

  USE_MODALS: false,

  scale: 1,
  zoomIndex: 0,

  // OUTLINE_LEVELS define possible OUTLINE_CONFIGURATIONS.
  OUTLINE_LEVELS: ['aggregation', 'level1', 'level2', 'level3', 'level4', 'level5', 'all'],
  OUTLINE_CONFIGURATIONS: {
    aggregation: { name: 'timelines.outlines.aggregation', level: 0 },
    level1:      { name: 'timelines.outlines.level1',      level: 1 },
    level2:      { name: 'timelines.outlines.level2',      level: 2 },
    level3:      { name: 'timelines.outlines.level3',      level: 3 },
    level4:      { name: 'timelines.outlines.level4',      level: 4 },
    level5:      { name: 'timelines.outlines.level5',      level: 5 },
    all:         { name: 'timelines.outlines.all',         level: Infinity }
  },

  // ZOOM_SCALES define possible ZOOM_CONFIGURATIONS.
  ZOOM_SCALES: ['yearly', 'quarterly', 'monthly', 'weekly', 'daily'],
  ZOOM_CONFIGURATIONS: {
    daily:     {name: 'timelines.zoom.days',     scale: 1.40, config: ['months', 'weeks', 'actualDays', 'weekDays']},
    weekly:    {name: 'timelines.zoom.weeks',    scale: 0.89, config: ['months', 'weeks', 'weekDays']},
    monthly:   {name: 'timelines.zoom.months',   scale: 0.53, config: ['years', 'months', 'weeks']},
    quarterly: {name: 'timelines.zoom.quarters', scale: 0.21, config: ['year-quarters', 'months', 'weeks']},
    yearly:    {name: 'timelines.zoom.years',    scale: 0.10, config: ['years', 'quarters', 'months']}
  },
  getScale: function() {
    var day = this.DAY_WIDTH * this.scale;
    var week = day * 7;
    var height = Timeline.PE_HEIGHT;

    return {
      height: height,
      week: week,
      day: day
    };
  },
  setScale: function(scale) {
    // returns width for specified scale
    if (!scale) {
      scale = this.scale;
    } else {
      this.scale = scale;
    }
    var days = this.getDaysBetween(
      this.getBeginning(),
      this.getEnd()
    );
    return days * this.DAY_WIDTH * scale;
  },
  getWidth: function() {

    // width is the wider of the currently visible chart dimensions
    // (adjusted_width) and the minimum space the timeline needs.
    return Math.max(this.adjusted_width, this.setScale() + 200);
  },
  resetWidth: function() {
    delete this.adjusted_width;
  },
  adjustWidth: function(width) {
    // adjusts for the currently visible chart dimensions.
    var old_adjusted_width = this.adjusted_width;

    this.adjusted_width = this.adjusted_width === undefined?
      width: Math.max(old_adjusted_width, Math.max(width, this.adjusted_width));

    if (old_adjusted_width < this.adjusted_width) {
      this.rebuildAll();
    }

    return this.adjusted_width;
  },
  getHeight: function() {
    return this.getMeasuredHeight() - this.getMeasuredScrollbarHeight();
  },
  scaleToFit: function(width) {
    var scale = width / (this.DAY_WIDTH * this.getDaysBetween(
      this.getBeginning(),
      this.getEnd()
    ));
    this.setScale(scale);
    return scale;
  },
  getColorParts: function(color) {
    return jQuery.map(color.match(/[0-9a-fA-F]{2}/g), function(e, i) {
      return parseInt(e, 16);
    });
  },
  getLimunanceFor: function(color) {
    var parts = this.getColorParts(color);
    var result = (0.299 * parts[0] + 0.587 * parts[1] + 0.114 * parts[2]) / 256;
    return result;
  },
  getMeasuredPathFromText: function(text, limit) {
    var font = this.paper.getFont('Bitstream Vera Sans');
    var o, char, glyph, fontPath = 'M0,0';
    var nonWhitespaceProgress = 0, totalFontProgress = 0, charProgress = 0;
    var p;

    if (typeof limit === "undefined") {
      limit = Infinity;
    }

    // cufón is awesóme.
    for (o = 0; o < text.length; o++) {
      char = text.charAt(o);
      if (font.glyphs[char] !== undefined &&
          font.glyphs[char].d !== undefined) {

        charProgress = font.glyphs[char].w || font.w;
        totalFontProgress += charProgress;

        // break if limit would be exceeded by appending this char.
        if (totalFontProgress > limit) {
          totalFontProgress -= charProgress;
          break;
        }

        glyph = Raphael.pathToRelative(font.glyphs[char].d);
        for (p = 0; p < glyph.length; p++) {
          fontPath += (p === 0 ? glyph[p].shift().toLowerCase() : glyph[p].shift()) + glyph[p].join(',');
        }

      } else {
        totalFontProgress += font.w;
      }
      if (!/\s/g.test(char)) {
        nonWhitespaceProgress = totalFontProgress;
      }
      fontPath += 'M' + totalFontProgress + ',0';
    }

    return {
      'path': fontPath,
      'progress': nonWhitespaceProgress
    };
  },

  expandTo: function(index) {
    var level;
    index = Math.max(index, 0);
    level = Timeline.OUTLINE_CONFIGURATIONS[Timeline.OUTLINE_LEVELS[index]].level;
    if (this.options.hide_tree_root) {
      level++;
    }
    level = this.getLefthandTree().expandTo(level);
    this.expansionIndex = index;
    this.rebuildAll();
  },

  zoom: function(index) {
    if (index === undefined) {
      index = this.zoomIndex;
    }
    index = Math.max(Math.min(this.ZOOM_SCALES.length - 1, index), 0);
    this.zoomIndex = index;
    var scale = Timeline.ZOOM_CONFIGURATIONS[Timeline.ZOOM_SCALES[index]].scale;
    this.setScale(scale);
    this.resetWidth();
    this.triggerResize();
    this.rebuildAll();
  },
  zoomIn: function() {
    this.zoom(this.zoomIndex + 1);
  },
  zoomOut: function() {
    this.zoom(this.zoomIndex - 1);
  },
  getSwimlaneStyles: function() {
    return [{
        textColor: '#000000',
        laneColor: '#e7e7e7'
      }, {
        textColor: '#000000',
        laneColor: '#797979'
      }, {
        // laneWidth: 1.5,
        textColor: '#000000',
        laneColor: '#424242'
      }, {
        // laneWidth: 2,
        textColor: '#000000',
        laneColor: '#000000'
      }];
  },
  getSwimlaneConfiguration: function() {
    return {
      'actualDays': {
        // actual days
        delimiter: this.getBeginning().moveToFirstDayOfMonth().moveToDayOfWeek(Date.CultureInfo.firstDayOfWeek, -1),
        caption: function() { return this.delimiter.toString('d'); },
        next: function() { return this.delimiter.addDays(1); },
        overrides: ['weekDays']
      },
      'weekDays': {
        // weekdays
        delimiter: this.getBeginning().moveToFirstDayOfMonth().moveToDayOfWeek(Date.CultureInfo.firstDayOfWeek, -1),
        caption: function() { return this.delimiter.toString('ddd')[0]; },
        next: function() { return this.delimiter.addDays(1); },
        overrides: ['actualDays']
      },
      'weeks': {
        // weeks
        delimiter: this.getBeginning().moveToFirstDayOfMonth().moveToDayOfWeek(Date.CultureInfo.firstDayOfWeek, -1),
        caption: function() { return this.delimiter.getWeekOfYear(); },
        next: function() { return this.delimiter.addWeeks(1); },
        overrides: ['weekDays', 'actualDays']
      },
      'months': {
        // months
        delimiter: this.getBeginning().moveToFirstDayOfMonth(),
        caption: function() { return Date.CultureInfo.abbreviatedMonthNames[this.delimiter.getMonth()]; },
        next: function() { return this.delimiter.addMonths(1); },
        overrides: ['actualDays', 'weekDays', 'quarters']
      },
      'year-quarters': {
        // quarters
        delimiter: this.getBeginning().moveToMonth(0, -1).moveToFirstDayOfMonth(),
        caption: function() { return Date.CultureInfo.abbreviatedQuarterNames[this.delimiter.getQuarter()] + " " + this.delimiter.toString('yyyy'); },
        next: function() { return this.delimiter.addQuarters(1); },
        overrides: ['actualDays', 'weekDays', 'months', 'quarters']
      },
      'quarters': {
        // quarters
        delimiter: this.getBeginning().moveToMonth(0, -1).moveToFirstDayOfMonth(),
        caption: function() { return Date.CultureInfo.abbreviatedQuarterNames[this.delimiter.getQuarter()]; },
        next: function() { return this.delimiter.addQuarters(1); },
        overrides: ['actualDays', 'weekDays', 'months']
      },
      'years': {
        // years
        delimiter: this.getBeginning().moveToMonth(0, -1).moveToFirstDayOfMonth(),
        caption: function() { return this.delimiter.toString('yyyy'); },
        next: function() { return this.delimiter.addYears(1); },
        overrides: ['actualDays', 'weekDays', 'months', 'quarters']
      }};
  },
  getAvailableRows: function() {
    var timeline = this;
    return {
      all: ['end_date', 'planning_element_types', 'project_status', 'project_type', 'responsible', 'start_date'],
      planning_element_types: function(data, pet, pt) {
        if (pet === undefined) {
          // nop
        } else if (pet === null) {
          return jQuery('<span class="tl-column">-</span>');
        } else {
          return jQuery('<span class="tl-column">' + timeline.escape(pet.name) + '</span>');
        }
      },
      project_status: function(data) {
        var status;
        if (data.getProjectStatus instanceof Function) {
          status = data.getProjectStatus();
        }
        if (status) {
          return jQuery('<span class="tl-column">' + timeline.escape(status.name) + '</span>');
        } else {
          return jQuery('<span class="tl-column">-</span>');
        }
      },
      project_type: function(data, pet, pt) {
        if (pt === undefined) {
          // nop
        } else if (pt === null) {
          return jQuery('<span class="tl-column">-</span>');
        } else {
          return jQuery('<span class="tl-column">' + timeline.escape(pt.name) + '</span>');
        }
      },
      responsible: function(data) {
        var result;
        if (data.responsible && data.responsible.name) {
          result = jQuery('<span class="tl-column">' + timeline.escape(data.responsible.name) + '</span>');
          if (data.is(Timeline.Project)) {
            result.addClass('tl-responsible');
          }
          return result;
        }
      },
      start_date: function(data) {
        var kind, result = '';
        if (data.start_date !== undefined) {
          if (data.alternate_start_date !== undefined && data.start_date !== data.alternate_start_date) {
            kind = (data.alternate_start_date < data.start_date? 'postponed' : 'preponed');
            result += '<span class="tl-historical">';
            result += timeline.escape(data.alternate_start_date);
            result += '<a href="javascript://" title="%t" class="%c"/>'
              .replace(/%t/, timeline.i18n('timelines.change'))
              .replace(/%c/, 'icon tl-icon-' + kind);
            result += '</span><br/>';
          }
          result += '<span class="tl-column tl-current tl-' + kind + '">' + timeline.escape(data.start_date) + '</span>';
          return jQuery(result);
        }
      },
      end_date: function(data) {
        var kind, result = '';
        if (data.end_date !== undefined) {
          if (data.alternate_end_date !== undefined && data.end_date !== data.alternate_end_date) {
            kind = (data.alternate_end_date < data.end_date? 'postponed' : 'preponed');
            result += '<span class="tl-historical">';
            result += timeline.escape(data.alternate_end_date);
            result += '<a href="javascript://" title="%t" class="%c"/>'
              .replace(/%t/, timeline.i18n('timelines.change'))
              .replace(/%c/, 'icon tl-icon-' + kind);
            result += '</span><br/>';
          }
          result += '<span class="tl-column tl-current tl-' + kind + '">' +
                    timeline.escape(data.end_date) + '</span>';
          return jQuery(result);
        }
      }
    };
  },
  getUiRoot: function() {
    return this.uiRoot;
  },
  getEventHandlerSuffix: function() {
    if (this.event_handler_suffix === undefined) {
      this.event_handler_suffix = this.getUiRoot().attr('id');
    }
    return this.event_handler_suffix;
  },
  getTooltip: function() {
    var tooltip = this.getUiRoot().find('.tl-tooltip');

    return tooltip;
  },
  getChart: function() {
    return this.getUiRoot().find('.tl-chart');
  },

  i18n: function(key) {
    var value = this.options.i18n[key];
    var message;
    if (value === undefined) {
      message = 'translation missing: ' + key;
      if (console && console.log) {
        console.log(message);
      }
      return message;
    } else {
      return value;
    }
  },

  setupUI: function() {

    this.setupToolbar();
    this.setupChart();
  },
  setupToolbar: function() {
    // ╭───────────────────────────────────────────────────────╮
    // │  Builds the following dom and adds it to root:        │
    // │                                                       │
    // │  <div class="tl-toolbar"> ... </div>                  │
    // ╰───────────────────────────────────────────────────────╯
    var toolbar = jQuery('<div class="tl-toolbar"></div>');
    var timeline = this;
    var i, c, containers = [
      0,
      1,
      0, 100, 0, 0, // zooming
      1,
      0, 0          // outline
    ];
    var icon = '<a href="javascript://" title="%t" class="%c"/>';

    for (i = 0; i < containers.length; i++) {
      c = jQuery('<div class="tl-toolbar-container"></div>');
      if (containers[i] !== 0) {
        c.css({
          'width': containers[i] + 'px',
          'height': '20px'
        });
      }
      containers[i] = c;
      toolbar.append(c);
    }
    this.getUiRoot().append(toolbar);

    var currentContainer = 0;

    if (Timeline.USE_MODALS) {

      // ╭───────────────────────────────────────────────────────╮
      // │  Add element                                          │
      // ╰───────────────────────────────────────────────────────╯

      containers[currentContainer++].append(
        jQuery(icon
          .replace(/%t/, timeline.i18n('timelines.new_planning_element'))
          .replace(/%c/, 'icon icon-add')
        ).click(function(e) {
          e.stopPropagation();
          timeline.addPlanningElement();
          return false;
        }));

      // ╭───────────────────────────────────────────────────────╮
      // │  Spacer                                               │
      // ╰───────────────────────────────────────────────────────╯

      containers[currentContainer++].css({
        'background-color': '#000000'
      });

    } else {
      currentContainer += 2;
    }

    // ╭───────────────────────────────────────────────────────╮
    // │  Zooming                                              │
    // ╰───────────────────────────────────────────────────────╯

    // drop-down
    var form = jQuery('<form></form>');
    var zooms = jQuery('<select name="zooms"></select>');
    for (i = 0; i < Timeline.ZOOM_SCALES.length; i++) {
      zooms.append(jQuery(
            '<option>' +
            timeline.i18n(Timeline.ZOOM_CONFIGURATIONS[Timeline.ZOOM_SCALES[i]].name) +
            '</option>'));
    }
    form.append(zooms);
    containers[currentContainer + 3].append(form);

    // slider
    var slider = jQuery('<div></div>').slider({
      min: 1,
      max: Timeline.ZOOM_SCALES.length,
      range: 'min',
      value: zooms[0].selectedIndex + 1,
      slide: function(event, ui) {
        zooms[0].selectedIndex = ui.value - 1;
      },
      change: function(event, ui) {
        zooms[0].selectedIndex = ui.value - 1;
        timeline.zoom(ui.value - 1);
      }
    }).css({
      // top right bottom left
      'margin': '4px 6px 3px'
    });
    containers[currentContainer + 1].append(slider);
    zooms.change(function() {
      slider.slider('value', this.selectedIndex + 1);
    });

    // zoom out
    containers[currentContainer].append(
      jQuery(icon
        .replace(/%t/, timeline.i18n('timelines.zoom.out'))
        .replace(/%c/, 'icon tl-icon-zoomout')
      ).click(function() {
        slider.slider('value', slider.slider('value') - 1);
      }));

    // zoom in
    containers[currentContainer + 2].append(
      jQuery(icon
        .replace(/%t/, timeline.i18n('timelines.zoom.in'))
        .replace(/%c/, 'icon tl-icon-zoomin')
      ).click(function() {
        slider.slider('value', slider.slider('value') + 1);
      }));

    currentContainer += 4;

    // ╭───────────────────────────────────────────────────────╮
    // │  Spacer                                               │
    // ╰───────────────────────────────────────────────────────╯

    containers[currentContainer++].css({
      'background-color': '#000000'
    });

    // ╭───────────────────────────────────────────────────────╮
    // │  Outline                                              │
    // ╰───────────────────────────────────────────────────────╯

    // drop-down
    // TODO this is very similar to the way the zoom dropdown is
    // assembled. Refactor to avoid code duplication!
    form = jQuery('<form></form>');
    var outlines = jQuery('<select name="outlines"></select>');
    for (i = 0; i < Timeline.OUTLINE_LEVELS.length; i++) {
      outlines.append(jQuery(
            '<option>' +
            timeline.i18n(Timeline.OUTLINE_CONFIGURATIONS[Timeline.OUTLINE_LEVELS[i]].name) +
            '</option>'));
    }
    form.append(outlines);
    containers[currentContainer + 1].append(form);

    outlines.change(function() {
      timeline.expandTo(this.selectedIndex);
    });

    // perform outline action again (icon mostly a divider from zooms)
    containers[currentContainer].append(
      jQuery(icon
        .replace(/%t/, timeline.i18n('timelines.outline'))
        .replace(/%c/, 'icon tl-icon-outline')
      ).click(function() {
        timeline.expandTo(outlines[0].selectedIndex);
      }));

    currentContainer += 2;

    this.updateToolbar = function() {
      slider.slider('value', timeline.zoomIndex + 1);
      outlines[0].selectedIndex = timeline.expansionIndex;
    };
  },
  setupChart: function() {

    // ╭───────────────────────────────────────────────────────╮
    // │  Builds the following dom and adds it to root:        │
    // │                                                       │
    // │  <div class="timeline tl-under-construction">         │
    // │    <div class="tl-left">                              │
    // │      <div class="tl-left-top tl-decoration"></div>    │
    // │      <div class="tl-left-main"></div>                 │
    // │    </div>                                             │
    // │    <div class="tl-right">                             │
    // │      <div class="tl-right-top tl-decoration"></div>   │
    // │      <div class="tl-right-main"></div> (optional)     │
    // │    </div>                                             │
    // │    <div class="tl-scrollcontainer">                   │
    // │      <!--div class="tl-decoration"></div-->           │
    // │      <div class="tl-chart"></div>                     │
    // │    </div>                                             │
    // │    <div class="tl-tooltip fade above in">             │
    // │      <div class="tl-tooltip-inner"></div>             │
    // │      <div class="tl-tooltip-arrow"></div>             │
    // │    </div>                                             │
    // │  </div>                                               │
    // ╰───────────────────────────────────────────────────────╯

    var timeline = jQuery('<div class="timeline tl-under-construction"></div>');

    var tlLeft = jQuery('<div class="tl-left"></div>')
      .append(jQuery('<div class="tl-left-top tl-decoration"></div>'))
      .append(jQuery('<div class="tl-left-main"></div>'));

    var tlRight = jQuery('<div class="tl-right"></div>')
      .append(jQuery('<div class="tl-right-top tl-decoration"></div>'))
      .append(jQuery('<div class="tl-right-main"></div>'));

    var paper = jQuery('<div class="tl-chart"></div>');

    // there is a bug in IE8 that draws over the left edge of the VML
    // graphic. This additional border compensates for that bug w/o
    // penalizing the design in other browsers.
    if (jQuery.browser.msie) {
      paper.css({'border-left': '1px solid white'});
      Timeline.BORDER_WIDTH_CORRECTION = Timeline.ORIGINAL_BORDER_WIDTH_CORRECTION + 1;
    }

    var tlScrollContainer = jQuery('<div class="tl-scrollcontainer"></div>')
      //.append(jQuery('<div class="tl-decoration"></div>'))
      .append(paper);

    var tlTooltip = jQuery('<div class="tl-tooltip fade above in"></div>')
      .append('<div class="tl-tooltip-inner"></div>')
      .append('<div class="tl-tooltip-arrow"></div>');

    timeline
      .append(tlLeft)
      .append(tlRight)
      .append(tlScrollContainer)
      .append(tlTooltip);

    this.getUiRoot().append(timeline);

    // store the paper element for later use.
    this.paperElement = paper[0];
  },

  completeUI: function() {
    var timeline = this;

    // construct tree on left-hand-side.
    this.rebuildTree();

    // lift the curtain, paper otherwise doesn't show w/ VML.
    jQuery('.timeline').removeClass('tl-under-construction');
    this.paper = new Raphael(this.paperElement, 640, 480);

    // perform some zooming. if there is a zoom level stored with the
    // report, zoom to it. otherwise, zoom out. this also constructs
    // timeline graph.
    if (this.options.zoom_factor &&
        this.options.zoom_factor.length === 1) {

      this.zoom(
        this.pnum(this.options.zoom_factor[0])
      );

    } else {
      this.zoomOut();
    }

    // perform initial outline expansion.
    if (this.options.initial_outline_expansion &&
        this.options.initial_outline_expansion.length === 1) {

      this.expandTo(
        this.pnum(this.options.initial_outline_expansion[0])
      );
    }

    // zooming and initial outline expansion have consequences in the
    // select inputs in the toolbar.
    this.updateToolbar();

    this.getChart().scroll(function() {
      timeline.adjustTooltip();
    });

    jQuery(window).scroll(function() {
      timeline.adjustTooltip();
    });
  },

  getMeasuredHeight: function() {
    return this.getUiRoot().find('.tl-left-main').height();
  },
  getMeasuredScrollbarHeight: function() {
    var p, div, h, hh;

    // this method is built on the assumption that the width of a
    // vertical scrollbar is equal o the height of a horizontal one. if
    // that symmetry is broken, this method will need to be repaired.

    if (this.scrollbar_height !== undefined) {
      return this.scrollbar_height;
    }

    p = jQuery('<p/>').css({
      'width':  "100%",
      'height': "200px"
    });

    div = jQuery('<div/>').css({
      'position':   "absolute",
      'top':        "0",
      'left':       "0",
      'visibility': "hidden",
      'width':      "200px",
      'height':     "150px",
      'overflow':   "hidden"
    });

    div.append(p);
    jQuery('body').append(div);
    h = p[0].offsetWidth;
    div.css({'overflow': 'scroll'});
    hh = p[0].offsetWidth;
    if (h === hh) {
      hh = div[0].clientWidth;
    }
    div.remove();

    this.scrollbar_height = (h - hh);
    return this.scrollbar_height;
  },

  escape: function(string) {
    return jQuery('<div/>').text(string).html();
  },
  psub: function(string, map) {
    return string.replace(/#\{(.+?)\}/g, function(m, p, o, s) { return map[p]; });
  },
  pnum: function(string) {
    return parseInt(string.replace(/[^\d\-]/g, ''), 10);
  },
  /**
   * Filter helper for multi select filters based on IDs.
   *
   * Assumption is that array is an array of strings while object is a object
   * with an id field which contains a number
   */
  filterOutBasedOnArray: function (array, object) {
    return !Timeline.idInArray(array, object);
  },
  idInArray: function (array, object) {
    // when object is not set, check if the (none) a.k.a. -1 option is selected
    var id = object ? object.id + '' : '-1';

    if (jQuery.isArray(array) && array.length > 0) {
      return jQuery.inArray(id, array) !== -1;
    }
    else {
      // if there is no array, we just accept.
      return true;
    }
  },

  rebuildAll: function() {
    var timeline = this;
    var root = timeline.getUiRoot();

    delete this.table_offset;

    window.clearTimeout(this.rebuildTimeout);
    this.rebuildTimeout = timeline.defer(function() {
      timeline.rebuildTree();

      // The minimum width of the whole timeline should be the actual
      // width of the table added to the minimum chart width. That way,
      // the floats never break.

      if (timeline.options.hide_chart == null) {
        root.find('.timeline').css({
          'min-width': root.find('.tl-left-main').width() +
                         Timeline.MIN_CHART_WIDTH
        });
      }

      if (timeline.options.hide_chart !== 'yes') {
        timeline.rebuildGraph();
      } else {
        var chart = timeline.getUiRoot().find('.tl-chart');
        chart.css({ display: 'none'});
      }
    });
  },
  rebuildTree: function() {
    var where = this.getUiRoot().find('.tl-left-main');
    var tree = this.getLefthandTree();
    var table = jQuery('<table></table>');
    var body = jQuery('<tbody></tbody>');
    var head = jQuery('<thead></thead>');
    var row, cell, link, span, text;
    var timeline = this;
    var rows = this.getAvailableRows();
    var first = true; // for the first row
    var previousGroup = -1;
    var headerHeight = this.decoHeight();

    // subtract 1px border if this is not firefox. in firefox, we need
    // an additional pixel in the header. no idea where this comes from,
    // it works fine in chrome and ie.
    if (jQuery.browser.mozilla === undefined) {
      headerHeight--;
    }

    // head
    table.append(head);
    row = jQuery('<tr></tr>');

    // there is always a name.
    cell = jQuery('<th class="tl-first-column"/>');
    cell.append(timeline.i18n('timelines.filter.column.name'));

    // only compensate for the chart decorations if we're actualy
    // showing one.
    if (timeline.options.hide_chart == null) {
      cell.css({'height': headerHeight + 'px'});
    }
    row.append(cell);

    // everything else.
    var header = function(key) {
      var th = jQuery('<th></th>');
      th.append(timeline.i18n('timelines.filter.column.' + key));
      return th;
    };
    jQuery.each(timeline.options.columns, function(i, e) {
      row.append(header(e));
    });
    head.append(row);

    // body
    table.append(body);

    row = jQuery('<tr></tr>');

    tree.iterateWithChildren(function(node, indent) {
      var data = node.getData();
      var pet = data.getPlanningElementType();
      var pt = data.getProjectType && data.getProjectType();
      var group;

      // create a new cell with the name for the current level.
      row = jQuery('<tr></tr>');
      cell = jQuery(
          '<td class="tl-first-column"></td>'
        );
      row.append(cell);

      var contentWrapper = jQuery('<span class="tl-word-ellipsis"></span>');

      cell.addClass('tl-indent-' + indent);

      // check for start of a new group.
      if (timeline.isGrouping() && data.is(Timeline.Project)) {
        if (indent === 0) {
          group = data.getFirstLevelGrouping();
          if (previousGroup !== group) {

            body.append(jQuery(
              '<tr><td class="tl-grouping" colspan="' +
              (timeline.options.columns.length + 1) + '"><span class="tl-word-ellipsis">' +
              timeline.escape(data.getFirstLevelGroupingName()) +
              '</span></td></tr>'));

            previousGroup = group;
          }
        }
      }

      if (node.hasChildren()) {
        cell.addClass(node.isExpanded() ? 'tl-expanded' : 'tl-collapsed');

        link = jQuery('<a href="javascript:;"/>');
        link.click({'node': node, 'timeline': timeline}, function(event) {
          event.data.node.toggle();
          event.data.timeline.rebuildAll();
        });
        link.append(node.isExpanded() ? '-' : '+');
        cell.append(link);
      }

      cell.append(contentWrapper);

      text = timeline.escape(data.name);
      if (data.getUrl instanceof Function) {
        text = jQuery('<a href="' + data.getUrl() + '" class="tl-discreet-link" target="_blank"/>').append(text).attr("title", text);
        text.click(function(event) {
          if (Timeline.USE_MODALS && !event.ctrlKey && !event.metaKey && data.is(Timeline.PlanningElement)) {
            timeline.modalHelper.createPlanningModal(
              'show',
              data.project.identifier,
              data.id
            );
            event.preventDefault();
          }
        });
      }

      if (data.is(Timeline.Project)) {
        text.addClass('tl-project');
      }

      span = jQuery('<span/>').append(text);
      contentWrapper.append(span);

      // the node will later need to know where on the screen the
      // corresponding table cell is, i.e. for computing the vertical
      // index for planning elements inside the chart.
      node.setDOMElement(cell);

      var added = data.is(Timeline.PlanningElement) && data.isNewlyAdded();
      var change_detected = added || data.is(Timeline.PlanningElement) && data.hasAlternateDates();
      var deleted = data.is(Timeline.PlanningElement) && data.isDeleted();

      // everything else
      jQuery.each(timeline.options.columns, function(i, e) {
        var cell = jQuery('<td></td>');
        cell.append(rows[e].call(data, data, pet, pt));
        row.append(cell);
      });
      body.append(row);

      if (data.is(Timeline.Project)) {
        row.addClass('tl-project-row');
      }

      if (change_detected) {
        span.prepend(

          // the empty span is for a rendering bug in chrome. the anchor
          // would not be displayed as inline, unless there is a change
          // in the css after the rendering (nop changes suffice) or
          // there is some prepended content. this span provides for
          // exactly that.

          jQuery('<span/><a href="javascript://" title="%t" class="%c"/>'
            .replace(/%t/, timeline.i18n('timelines.change'))
            .replace(/%c/, added? 'icon tl-icon-added' : deleted? 'icon tl-icon-deleted' : 'icon tl-icon-changed')
          ));
      }

      // attribute a special class to the first row. this is for
      // additional indentation, however only when we are not in a
      // grouping.

      if (first) {
        first = false;
        if (!timeline.isGrouping()) {
          row.addClass('tl-first-row');
        }
      }
    });

    // attribute a special class to the last row
    if (row !== undefined) {
      row.addClass('tl-last-row');
      row.find('td').append(timeline.scrollbarBox());
    }

    where.empty().append(table);

    var maxWidth = jQuery("#content").width() * 0.25;
    jQuery(".tl-word-ellipsis").each(function (i, e) {
      e = jQuery(e);

      if (e.parent().width() > maxWidth) {
        var indent = e.offset().left - e.parent().offset().left;

        e.css("width", maxWidth - indent);
      }
    });
  },
  scrollbarBox: function() {
    var scrollbar_height = this.getMeasuredScrollbarHeight();
    return jQuery('<div class="tl-invisible"/>').css({
      'height': scrollbar_height,
      'width':  scrollbar_height
    });
  },
  decoHeight: function() {
    var config = Timeline.ZOOM_SCALES[this.zoomIndex];
    var lanes = Timeline.ZOOM_CONFIGURATIONS[config].config.length;
    return 12 * lanes; // -1 is for coordinates starting at 0.
  },
  getPaper: function() {
    return this.paper;
  },
  rebuildGraph: function() {
    var timeline = this;
    var tree = timeline.getLefthandTree();
    var chart = timeline.getUiRoot().find('.tl-chart');

    chart.css({'display': 'none'});

    var width = timeline.getWidth();
    var height = timeline.getHeight();

    // clear and resize
    timeline.paper.clear();
    timeline.paper.setSize(width, height);

    timeline.defer(function() {
      // rebuild content
      timeline.rebuildBackground(tree, width, height);
      chart.css({'display': 'block'});
      timeline.rebuildForeground(tree);
    });
  },
  finishGraph: function() {
    var root = this.getUiRoot();
    var info = jQuery('<span class="tl-hidden-info tl-finished"></span>');

    // this will be called asynchronously and finishes up the graph
    // building process.
    this.setupEventHandlers();

    root.append(info);
  },
  rebuildBackground: function(tree, width, height) {
    var beginning = this.getBeginning();
    var scale = this.getScale();
    var end = this.getEnd();
    var deco = this.decoHeight();

    deco--;

    this.paper.rect(0, deco, width, height).attr({
      'fill': '#fff',
      'stroke': '#fff', //
      'stroke-opacity': 0,
      'stroke-width': 0
    });

    // horizontal bar.
    this.paper.path(
      this.psub('M0 #{y}H#{w}', {
        y: deco + 0.5, // the vertical line otherwise overlaps.
        w: width
      })
    );

    // *** beginning decorations ***

    var lastDivider, caption, captionElement, bbox, dividerPath;
    var padding = 2;

    lastDivider = 0;

    var swimlanes = this.getSwimlaneConfiguration();
    var styles = this.getSwimlaneStyles();
    var config = Timeline.ZOOM_SCALES[this.zoomIndex];

    var key, i, left, first, timeline = this;
    var m, x, y;

    var currentStyle = 0, lastOverrideGroup;

    for (i = Timeline.ZOOM_CONFIGURATIONS[config].config.length - 1; i >= 0; i--) {
      key = Timeline.ZOOM_CONFIGURATIONS[config].config[i];
      if (swimlanes.hasOwnProperty(key)) {

        // if the current swimlane has more overrides, we assume a
        // change in quality of the seperation and switch styles to a
        // more solid one. lastOverrideGroup is set to the length of the
        // override-array of the current swimlane.

        if (swimlanes[key].overrides.length > lastOverrideGroup) {
          currentStyle++;
        }
        lastOverrideGroup = swimlanes[key].overrides.length;

        lastDivider = 0;
        dividerPath = '';
        first = true;
        while (lastDivider < width || swimlanes[key].delimiter.compareTo(end) <= 0) {

          caption = swimlanes[key].caption() || '';
          if (caption.length === undefined) {
            caption = caption.toString(); // caption needs to be a string.
          }
          swimlanes[key].next();
          left = timeline.getDaysBetween(beginning, swimlanes[key].delimiter) * scale.day;
          bbox = {height: 8};

          m = timeline.getMeasuredPathFromText(caption);
          x = (lastDivider + (left - lastDivider) / 2) - (m.progress / 16);
          y = (deco - padding);

          if (jQuery.browser.msie && jQuery.browser.version === '8.0') {
            y -= 2; // ugly, but neccessary.
          }

          captionElement = timeline.paper.path(m.path);

          captionElement
            .translate(x, y)
            .scale(0.125, 0.125, 0, 0)
            .attr({
              'fill': styles[currentStyle].textColor || timeline.DEFAULT_COLOR,
              'stroke': 'none'
            });

          lastDivider = left;
          dividerPath += timeline.psub('M#{x} #{y}v#{b} M#{x} #{d}v#{h}', {
            x: left,
            y: deco - bbox.height - 2 * padding,
            h: height,
            b: bbox.height + 2 * padding,
            d: timeline.decoHeight() + 1
          });
        }

        timeline.paper.path(dividerPath).attr({
          'stroke': styles[currentStyle].laneColor || timeline.DEFAULT_LANE_COLOR,
          'stroke-width': styles[currentStyle].laneWidth || timeline.DEFAULT_LANE_WIDTH,
          'stroke-linecap': 'butt' // the vertical line otherwise overlaps.
        });

        // altered deco ceiling for next decorations.
        deco -= bbox.height + 2 * padding;

        // horizontal bar.
        timeline.paper.path(
          timeline.psub('M0 #{y}H#{w}', {
            y: deco + 0.5, // the vertical line otherwise overlaps.
            w: width
          })
        );
      }
    }

    this.frameLine();
    this.nowLine();
  },
  getRelativeVerticalOffsetCorrectionForIE8: function() {
    if (this.relative_vertical_offset_correction_for_ie8 === undefined) {
      var table = this.getUiRoot().find('table').first();
      var lastCell = table.find('td').last();

      var height_from_cell =
        lastCell.last().outerHeight() +
        lastCell.last().position().top -
        table.position().top;

      var height_from_table = table.outerHeight();

      this.relative_vertical_offset_correction_for_ie8 = 1 + height_from_table - height_from_cell;
    }
    return this.relative_vertical_offset_correction_for_ie8;
  },
  getRelativeVerticalOffset: function(offset) {
    var result;
    if (this.table_offset === undefined) {
      this.table_offset = this.getUiRoot().find('.tl-left-main table').position().top;
    }
    if (offset !== undefined) {
      result = offset.position().top - this.table_offset;
      if (jQuery.browser.msie) {
        result += this.getRelativeVerticalOffsetCorrectionForIE8();
      }
      return result;
    }
    return this.table_offset;
  },
  getRelativeVerticalBottomOffset: function(offset) {
    var result;
    result = this.getRelativeVerticalOffset(offset);
    if (offset.find("div").length == 1) {
      result -= jQuery(offset.find("div")[0]).height();
    }
    if (offset !== undefined)
      result += offset.outerHeight();
    return result;
  },
  rebuildForeground: function(tree) {
    var timeline = this;
    var previousGrouping = -1;
    var grouping;
    var width = timeline.getWidth();
    var previousNode;
    var render_bucket = [];
    var pre_render_bucket = [];
    var post_render_bucket = [];
    var text_render_bucket = [];

    //iterate over all planning elements and find vertical ones to draw.
    jQuery.each(timeline.verticalPlanningElementIds(), function (i, e) {
      var pl = timeline.getPlanningElement(e);

      // the planning element should have been loaded already. however,
      // it might not have been, or it might not even exist. in that
      // case, we simply ignore it.
      if (pl === undefined) {
        return;
      }

      var pet = pl.getPlanningElementType();

      var node = Object.create(Timeline.TreeNode);
      node.setData(pl);

      if (pl.vertical) {
        if (pet && pet.is_milestone) {
          post_render_bucket.push(function () {
            pl.renderVertical(node);
          });
        } else {
          pre_render_bucket.push(function () {
            pl.renderVertical(node);
          });
        }
      }
    });

    tree.iterateWithChildren(function(node, indent, index) {
      var currentElement = node.getDOMElement();
      var currentOffset = timeline.getRelativeVerticalOffset(currentElement);
      var previousElement, previousEnd, groupHeight;
      var groupingChanged = false;
      var pl = node.getData();

      // if the grouping changed, put a grey box here.

      if (timeline.isGrouping() && indent === 0 && pl.is(Timeline.Project)) {
        grouping = pl.getFirstLevelGrouping();
        if (previousGrouping !== grouping) {

          groupingChanged = true;

          // previousEnd is the vertical position at which a previous
          // element ended. It is calculated by adding the previous
          // element's vertical offset to it's height.

          if (previousNode !== undefined) {
            previousElement = previousNode.getDOMElement();
            previousEnd = timeline.getRelativeVerticalOffset(previousElement) +
                previousElement.outerHeight();
          } else {

            // Reading decoHeight does not work equally well in
            // SVG/VML and WebKit/Mozilla, so we need some additional
            // adjustment. This is cumulative to the alterations for
            // anti-aliasing below.

            previousEnd = timeline.decoHeight();
            if (jQuery.browser.webkit) {
              previousEnd -= 1;
            } else if (jQuery.browser.msie) {
              previousEnd += 1;
            }
          }

          // groupHeight is the height gap between the vertical position
          // at which the current element begins (currentOffset) and the
          // position the previous element ended (previousEnd).

          groupHeight = currentOffset - previousEnd;

          // 0.5 is added or subtracted for subpixel anti-aliasing to
          // produce a sharp edge. Webkit seems to tends to anti-alias
          // upwards, while trident and gecko need to be corrected in
          // the other direction.

          if (jQuery.browser.webkit) {
            previousEnd += 0.5;
          } else {
            previousEnd -= 0.5;
          }

          if (jQuery.browser.msie) {
            previousEnd -= timeline.getRelativeVerticalOffsetCorrectionForIE8();
            groupHeight += timeline.getRelativeVerticalOffsetCorrectionForIE8();
          }

          // draw grey box.

          timeline.paper.rect(
            Timeline.GROUP_BAR_INDENT,
            previousEnd,
            width - 2 * Timeline.GROUP_BAR_INDENT,
            groupHeight
          ).attr({
            'fill': '#bbb',
            'fill-opacity': 0.5,
            'stroke-width': 1,
            'stroke-opacity': 1,
            'stroke': Timeline.DEFAULT_STROKE_COLOR
          });

          previousGrouping = grouping;
        }

      }

      // if there is a new project, draw a black line.

      if (pl.is(Timeline.Project)) {

        if (!groupingChanged) {

          if (jQuery.browser.webkit) {
            currentOffset += 0.5;
          } else {
            currentOffset -= 0.5;
          }

          // draw lines between projects
          timeline.paper.path(
            timeline.psub('M0 #{y}h#{w}', {
              y: currentOffset,
              w: width
            })
          ).attr({
            'stroke-width': 1,
            'stroke': Timeline.DEFAULT_STROKE_COLOR
          });

        }

      } else if (pl.is(Timeline.PlanningElement)) {

      }

      previousNode = node;

      if (pl.is(Timeline.PlanningElement)) {
        text_render_bucket.push(function () {
          pl.renderForeground(node);
        });
      }

      render_bucket.push(function() {
        pl.render(node);
      });
    });

    var render_next_bucket = function() {
      if (jQuery.each(pre_render_bucket.splice(0, Timeline.RENDER_BUCKETS), function(i, e) {
          e.call();
        }).length !== 0) {
        timeline.defer(render_next_bucket);
      } else if (jQuery.each(render_bucket.splice(0, Timeline.RENDER_BUCKETS), function(i, e) {
            e.call();
          }).length !== 0) {
        timeline.defer(render_next_bucket);
      } else if (jQuery.each(post_render_bucket.splice(0, Timeline.RENDER_BUCKETS), function(i, e) {
            e.call();
          }).length !== 0) {
        timeline.defer(render_next_bucket);
      } else if (jQuery.each(text_render_bucket.splice(0, Timeline.RENDER_BUCKETS), function(i, e) {
            e.call();
          }).length !== 0) {
        timeline.defer(render_next_bucket);
      } else {
        timeline.finishGraph();
      }
    };

    render_next_bucket();
  },

  frameLine: function () {
    var timeline = this;
    var scale = timeline.getScale();
    var beginning = timeline.getBeginning();
    var decoHeight = timeline.decoHeight();
    var linePosition;

    this.calculateTimeFilter();

    if (this.frameStart) {
      linePosition = (timeline.getDaysBetween(beginning, this.frameStart)) * scale.day;

      timeline.paper.path(
        timeline.psub("M#{position} #{top}L#{position} #{height}", {
          'position': linePosition,
          'top': decoHeight,
          'height': this.getHeight()
        })
      ).attr({
        'stroke': 'blue',
        'stroke-dasharray': '- '
      });
    }

    if (this.frameEnd) {
      linePosition = ((timeline.getDaysBetween(beginning, this.frameEnd) + 1) * scale.day);

      timeline.paper.path(
        timeline.psub("M#{position} #{top}L#{position} #{height}", {
          'position': linePosition,
          'top': decoHeight,
          'height': this.getHeight()
        })
      ).attr({
        'stroke': 'blue',
        'stroke-dasharray': '- '
      });
    }
  },

  nowLine: function () {
    var timeline = this;
    var scale = timeline.getScale();
    var beginning = timeline.getBeginning();

    var todayPosition = (timeline.getDaysBetween(beginning, Date.today())) * scale.day;
    todayPosition += (Date.now() - Date.today()) / Date.DAY * scale.day;

    var decoHeight = timeline.decoHeight();

    var currentTimeElement = timeline.paper.path(
      timeline.psub("M#{today} #{top}L#{today} #{height}", {
        'today': todayPosition,
        'top': decoHeight,
        'height': this.getHeight()
      })
    ).attr({
      'stroke': 'red',
      'stroke-dasharray': '- '
    });

    var setDateTime = 5 * 60 * 1000;

    var setDate = function () {
      var newTodayPosition = (timeline.getDaysBetween(beginning, Date.today())) * scale.day;
      newTodayPosition += (Date.now() - Date.today()) / Date.DAY * scale.day;

      if (Math.abs(newTodayPosition - todayPosition) > 0.1) {
        currentTimeElement.transform(
          timeline.psub("t#{trans},0", {
            'trans': newTodayPosition - todayPosition
          })
        );
      }

      if (scale.day === timeline.getScale().day) {
        window.setTimeout(setDate, setDateTime);
      }
    };

    window.setTimeout(setDate, setDateTime);
  },

  adjustTooltip: function(renderable, element) {
    renderable = renderable || this.currentNode;
    element = element || this.currentElement;
    if (!renderable) {
      return;
    }

    var chart = this.getChart();
    var offset = chart.position();
    var tooltip = this.getTooltip();
    var bbox = element.getBBox();
    var content = tooltip.find('.tl-tooltip-inner');
    var arrow = tooltip.find('.tl-tooltip-arrow');
    var arrowOffset = this.pnum(arrow.css('left'));
    var padding = (tooltip.outerWidth() - tooltip.width()) / 2;
    var duration = tooltip.css('display') !== 'none' ? 0 : 0;
    var info = "";
    var r = renderable.getResponsible();

    // construct tooltip content information.

    info += "<b>";
    info += this.escape(renderable.name);
    info += "</b>";
    if (renderable.is(Timeline.PlanningElement)) {
      info += " (*" + renderable.id + ")";
    }
    info += "<br/>";
    info += this.escape(renderable.start_date);
    if (renderable.end_date !== renderable.start_date) {
      // only have a second date if it is different.
      info += "–" + this.escape(renderable.end_date);
    }
    info += "<br/>";
    if (r && r.name) { // if there is a responsible, show the name.
      info += r.name;
    }

    content.html(info);

    // calculate position of tooltip
    var left = offset.left;
    left -= chart.scrollLeft();
    left += bbox.x;
    if (renderable.start_date && renderable.end_date) {
      left += bbox.width / 2;
    } else if (renderable.end_date) {
      left += bbox.width - Timeline.HOVER_THRESHOLD;
    } else {
      left += Timeline.HOVER_THRESHOLD;
    }
    left -= arrowOffset;

    var min_left = this.getUiRoot().find('.tl-left').position().left;
    min_left += this.getUiRoot().find('.tl-left').width();
    min_left -= arrowOffset;

    var max_left = this.getUiRoot().find('.tl-right').position().left;
    max_left -= tooltip.outerWidth();
    max_left -= padding;
    max_left += arrowOffset;

    left = Math.max(min_left, Math.min(max_left, left));

    var margin = offset.left;
    margin -= chart.scrollLeft();
    margin += (bbox.x);
    if (renderable.start_date && renderable.end_date) {
      margin += bbox.width / 2;
    } else if (renderable.end_date) {
      margin += bbox.width - Timeline.HOVER_THRESHOLD;
    } else {
      margin += Timeline.HOVER_THRESHOLD;
    }
    margin -= left;
    margin -= arrowOffset;

    var max_margin = tooltip.width();
    max_margin -= padding;
    max_margin -= arrowOffset;

    margin = Math.min(max_margin, Math.max(margin, 0));
    margin -= padding;

    var top = offset.top;
    top += bbox.y;
    top -= tooltip.outerHeight();
    top--; // random offset.

    if (top < jQuery(window).scrollTop() - 80) {
      top = jQuery(window).scrollTop() - 80;
    }

    this.currentNode = renderable;
    this.currentElement = element;
    tooltip.clearQueue();
    arrow.clearQueue();

    tooltip.animate({left: left, top: top}, duration, 'swing');
    arrow.animate({'margin-left': margin}, duration, 'swing');
  },

  setupEventHandlers: function() {
    var tree = this.getLefthandTree();
    this.setupResizeHandlers();
    //this.setupHoverHandlers(tree);
  },
  setupResizeHandlers: function() {
    var timeline = this, timeout;
    var handler_name = 'resize.' + timeline.getEventHandlerSuffix();

    jQuery(window).unbind(handler_name);
    jQuery(window).bind(handler_name, function() {

      window.clearTimeout(timeout);
      timeout = window.setTimeout(function() {
        timeline.triggerResize();
      }, 1087); // http://dilbert.com/strips/comic/2008-05-08/
    });
  },
  triggerResize: function() {
    var root = this.getUiRoot();
    var width = root.width() - root.find('.tl-left-main').width() -
                  Timeline.BORDER_WIDTH_CORRECTION;
    this.adjustWidth(width);
  },
  addHoverHandler: function(node, e) {
    var tooltip = this.getTooltip();
    var timeline = this;

    e.unhover();
    e.click(function(e) {
      if (Timeline.USE_MODALS) {
        var payload = node.getData();
        timeline.modalHelper.createPlanningModal(
          'show',
          payload.project.identifier,
          payload.id
        );
        e.stopPropagation();
      }
    });
    e.attr({'cursor': 'pointer'});
    e.hover(
      function() {
        timeline.adjustTooltip(node.getData(), e);
        tooltip.show();
      },
      function() {
        delete tooltip.currentNode;
        delete tooltip.currentElement;
        tooltip.hide();
      },
      node, node
    );
  },

  addPlanningElement: function() {
    var projects = this.projects;
    var project, projectID;

    for (project in projects) {
      if (projects.hasOwnProperty(project)) {
        if (projects[project].permissions.edit_planning_elements === true) {
          projectID = projects[project].identifier;
          break;
        }
      }
    }

    if (typeof projectID !== "undefined") {
      this.modalHelper.createPlanningModal("new", projectID);
    }
  }
};

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
