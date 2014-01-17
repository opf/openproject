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

Timeline.TimelineLoader = (function () {

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
        Timeline.Status,
        Timeline.PlanningElementType,
        Timeline.HistoricalPlanningElement,
        Timeline.PlanningElement,
        Timeline.ProjectType,
        Timeline.Project,
        Timeline.ProjectAssociation,
        Timeline.Reporting,
        Timeline.User
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

        this.augmentPlanningElementsWithHistoricalData();
        this.augmentPlanningElementsWithAllKindsOfStuff();
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
      this.data[type.identifier][id] = element;
      return this.data[type.identifier][id];
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
        // TODO this somehow didn't make the change to reporting_to_project_id and project_id.
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

    DataEnhancer.prototype.augmentElementAttributesWithUser = function (e, attributes) {
      if (this.data[Timeline.User.identifier]) {
        var k, curAttr;
        for (k = 0; k < attributes.length; k += 1) {
          curAttr = attributes[k];
          if (e[curAttr]) {
            e[curAttr.replace(/_id$/, "")] = this.getElement(Timeline.User,
                                              e[curAttr]);
          }

          delete e[curAttr];
        }
      }
    };

    DataEnhancer.prototype.augmentProjectElementWithUser = function (p) {
      this.augmentElementAttributesWithUser(p, Timeline.USER_ATTRIBUTES.PROJECT);
    };

    DataEnhancer.prototype.augmentProjectsWithProjectTypesAndAssociations = function () {
      var dataEnhancer = this;

      jQuery.each(dataEnhancer.getElements(Timeline.Project), function (i, e) {

        dataEnhancer.augmentProjectElementWithUser(e);

        // project_type ← project
        if (e.project_type_id !== undefined) {
          var project_type = dataEnhancer.getElement(Timeline.ProjectType, e.project_type_id);

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

            other = dataEnhancer.getElement(Timeline.Project, a.to_project_id);
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
        if (e.parent_id) {
          e.parent = dataEnhancer.getElement(Timeline.Project, e.parent_id);
        }
        delete e.parent_id;
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

        pe.historical_element = jQuery.extend(Object.create(Timeline.PlanningElement), e);
      });

      dataEnhancer.setElementMap(Timeline.HistoricalPlanningElement, undefined);
    };

    DataEnhancer.prototype.augmentPlanningElementWithStatus = function (pe) {
      // planning_element → planning_element_type
      if (pe.status_id) {
        pe.status = this.getElement(Timeline.Status,
                                    pe.status_id);
      }
      delete pe.status_id;
    };

    DataEnhancer.prototype.augmentPlanningElementWithUser = function (pe) {
      this.augmentElementAttributesWithUser(pe, Timeline.USER_ATTRIBUTES.PLANNING_ELEMENT);
    };

    DataEnhancer.prototype.augmentPlanningElementWithType = function (pe) {
      // planning_element → planning_element_type
      if (pe.type_id) {
        pe.planning_element_type = this.getElement(Timeline.PlanningElementType,
                                                   pe.type_id);
      }
      delete pe.type_id;
    };

    DataEnhancer.prototype.augmentPlanningElementWithProject = function (pe) {
      var project = this.getElement(Timeline.Project, pe.project_id);

      // there might not be such a project, due to insufficient rights
      // and the fact that some user with more rights originally created
      // the report.
      if (!project) {
        // TODO some flag indicating that something is wrong/missing.
        return;
      }

      // planning_element → project
      pe.project = project;
    };

    DataEnhancer.prototype.augmentPlanningElementWithParent = function (pe) {
      if (pe.parent_id) {
        var parent = this.getElement(Timeline.PlanningElement, pe.parent_id);

        if (parent !== undefined) {

          // planning_element ↔ planning_element
          if (parent.planning_elements === undefined) {
            parent.planning_elements = [];
          }
          parent.planning_elements.push(pe);
          pe.parent = parent;
        }

      } else {
        var project = pe.project;
        if (project) {
          // planning_element ← project
          if (project.planning_elements === undefined) {
            project.planning_elements = [];
          }
          project.planning_elements.push(pe);
        }
      }
    };

    DataEnhancer.prototype.augmentPlanningElementsWithAllKindsOfStuff = function () {
      var dataEnhancer = this;

      jQuery.each(dataEnhancer.getElements(Timeline.PlanningElement), function (i, e) {
        dataEnhancer.augmentPlanningElementWithStatus(e);
        dataEnhancer.augmentPlanningElementWithType(e);
        dataEnhancer.augmentPlanningElementWithProject(e);
        dataEnhancer.augmentPlanningElementWithParent(e);
        dataEnhancer.augmentPlanningElementWithUser(e);
        if (e.historical_element) {
          dataEnhancer.augmentPlanningElementWithStatus(e.historical_element);
          dataEnhancer.augmentPlanningElementWithType(e.historical_element);
        }
      });
    };

    DataEnhancer.prototype.augmentPlanningElementsWithVerticalityData = function () {
      var dataEnhancer = this;

      jQuery.each(dataEnhancer.getElements(Timeline.PlanningElement), function (i, e) {
        var pe = dataEnhancer.getElement(Timeline.PlanningElement, e.id);
        var pet = pe.getPlanningElementType();

        pe.vertical = this.timeline.verticalPlanningElementIds().indexOf(pe.id) !== -1;
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

      this.die = function () {
        this.dataEnhancer.die.apply(this.dataEnhancer, arguments);
      };

      jQuery(this.loader).on('success', jQuery.proxy(this, 'onLoadSuccess'))
                         .on('error',   jQuery.proxy(this, 'onLoadError'))
                         .on('empty',   jQuery.proxy(this, 'onLoadComplete'));
    };

    TimelineLoader.QueueingLoader = QueueingLoader;


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
    };

    TimelineLoader.prototype.registerGlobalElements = function () {

      this.loader.register(
          Timeline.Status.identifier,
          { url : this.globalPrefix + '/statuses.json' });
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

    TimelineLoader.prototype.registerUsers = function (ids) {

      this.inChunks(ids, function (user_ids_of_packet, i) {

        this.loader.register(
            Timeline.User.identifier + '_' + i,
            { url : this.globalPrefix +
                    '/users.json?ids=' +
                    user_ids_of_packet.join(',')},
            { storeIn : Timeline.User.identifier }
          );
      });
    };

    TimelineLoader.prototype.provideServerSideFilterHashTypes = function (hash) {
      if (this.options.planning_element_types !== undefined) {
        hash.type_id = this.options.planning_element_types;
      }
    };

    TimelineLoader.prototype.provideServerSideFilterHashStatus = function (hash) {
      if (this.options.planning_element_status !== undefined) {
        hash.status_id = this.options.planning_element_status;
      }
    };

    TimelineLoader.prototype.provideServerSideFilterHashResponsibles = function (hash) {
      if (this.options.planning_element_responsibles !== undefined) {
        hash.responsible_id = this.options.planning_element_responsibles;
      }
    };

    TimelineLoader.prototype.provideServerSideFilterHashAssignee = function (hash) {
      if (this.options.planning_element_assignee !== undefined) {
        hash.assigned_to_id = this.options.planning_element_assignee;
      }
    };

    TimelineLoader.prototype.provideServerSideFilterHash = function() {
      var result = {};
      this.provideServerSideFilterHashTypes(result);
      this.provideServerSideFilterHashResponsibles(result);
      this.provideServerSideFilterHashStatus(result);
      this.provideServerSideFilterHashAssignee(result);
      return result;
    };

    TimelineLoader.prototype.registerPlanningElements = function (ids) {

      this.inChunks(ids, function (projectIdsOfPacket, i) {
        var projectPrefix = this.options.url_prefix +
                            this.options.api_prefix +
                            this.options.project_prefix +
                            "/" +
                            projectIdsOfPacket.join(',');

        var qsb = new Timeline.FilterQueryStringBuilder(
          this.provideServerSideFilterHash());

        // load current planning elements.
        this.loader.register(
          Timeline.PlanningElement.identifier + '_' + i,
          { url : qsb.build(projectPrefix + '/planning_elements.json') },
          { storeIn: Timeline.PlanningElement.identifier }
        );

        // load historical planning elements.
        if (this.options.target_time) {
          this.loader.register(
            Timeline.HistoricalPlanningElement.identifier + '_' + i,
            { url : qsb.append({ at_time: this.options.target_time })
                       .build(projectPrefix + '/planning_elements.json') },
            { storeIn: Timeline.HistoricalPlanningElement.identifier,
              readFrom: Timeline.PlanningElement.identifier }
          );
        }
      });
    };


    TimelineLoader.prototype.registerPlanningElementsByID = function (ids) {

      this.inChunks(ids, function (planningElementIdsOfPacket, i) {
        var projectPrefix = this.options.url_prefix +
                            this.options.api_prefix;

        // load current planning elements.
        this.loader.register(
          Timeline.PlanningElement.identifier + '_IDS_' + i,
          { url : projectPrefix +
                  '/planning_elements.json?ids=' +
                  planningElementIdsOfPacket.join(',')},
          { storeIn: Timeline.PlanningElement.identifier }
        );

        // load historical planning elements.
        // TODO: load historical PEs here!
        if (this.options.target_time) {
          this.loader.register(
            Timeline.HistoricalPlanningElement.identifier + '_IDS_' + i,
            { url : projectPrefix +
                    '/planning_elements.json?ids=' +
                    planningElementIdsOfPacket.join(',') },
            { storeIn: Timeline.HistoricalPlanningElement.identifier,
              readFrom: Timeline.PlanningElement.identifier }
          );
        }
      });
    };

    TimelineLoader.prototype.inChunks = function (elements, iter) {
      var i, current_elements;

      i = 0;
      elements = elements.slice();

      while (elements.length > 0) {
        i++;

        current_elements = elements.splice(0, Timeline.PROJECT_ID_BLOCK_SIZE);

        iter.call(this, current_elements, i);
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

    function addUserIDsFromElementAttributes(results, attributes, element) {
      var k, userid;
      for (k = 0;  k < attributes.length; k += 1) {
        userid = element[attributes[k]];
        if (userid && results.indexOf(userid) === -1) {
          results.push(userid);
        }
      }
    }

    function addUserIDsForElementsByAttribute(results, attributes, elements) {
      var i, keys = Object.keys(elements), current;
      for (i = 0; i < keys.length; i += 1) {
        current = elements[keys[i]];

        addUserIDsFromElementAttributes(results, attributes, current);
      }
    }

    TimelineLoader.prototype.getUsersToLoad = function () {
      var results = [];

      addUserIDsForElementsByAttribute(results, Timeline.USER_ATTRIBUTES.PLANNING_ELEMENT, this.data.planning_elements);
      addUserIDsForElementsByAttribute(results, Timeline.USER_ATTRIBUTES.PROJECT, this.data.projects);

      return results;
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

    TimelineLoader.prototype.shouldLoadUsers = function (lastLoaded) {
      if (this.doneLoading(Timeline.Project) &&
          this.doneLoading(Timeline.Reporting) &&
          this.doneLoading(Timeline.ProjectType) &&
          this.doneLoading(Timeline.PlanningElement)) {

        // this will not work for pes from another project (like vertical pes)!
        // but as we do not display users for this data currently,
        // we will not add them yet
        this.shouldLoadUsers = function () { return false; };

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
      } else if (this.shouldLoadPlanningElements(identifier)) {
        this.data = this.dataEnhancer.enhance(this.data);

        this.registerPlanningElements(this.getRelevantProjectIdsBasedOnProjects());
      } else {
        if (this.shouldLoadRemainingPlanningElements(identifier)) {
          this.registerPlanningElementsByID(this.getRemainingPlanningElements());
        }

        if (this.shouldLoadUsers(identifier)) {
         this.registerUsers(this.getUsersToLoad());
        }
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
  })();
