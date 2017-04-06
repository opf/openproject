//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

module.exports = function($q, FilterQueryStringBuilder, Color, HistoricalPlanningElement, PlanningElement, PlanningElementType, Project, ProjectAssociation, ProjectType, Reporting, Status, Timeline, User, CustomField, PathHelper) {

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
   *       // console.log("'success' triggered for", this);
   *       // console.log("identifier used in register:",  args.identifier);
   *       // console.log("context provided in register:", args.context);
   *       // console.log("data returned by the server:",  args.data);
   *     });
   *
   *     jQuery(myLoader).on("error", function (e, args) {
   *       // console.log("'error' triggered for ", this);
   *       // console.log("identifier used in register:",  args.identifier);
   *       // console.log("context provided in register:", args.context);
   *       // console.log("textStatus provided by jqXHR:", args.textStatus);
   *     });
   *
   *     jQuery(myLoader).on("empty", function (e) {
   *       // console.log("'empty' triggered for ", this);
   *     });
   *
   */
  var QueueingLoader = function (ajaxDefaults) {
    this.ajaxDefaults = ajaxDefaults;
    this.registered   = {};
    this.loading      = {};
    this.TimelineLoaderService = {};
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
    // console.log('- QueueingLoader: load');

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
    // console.log('- QueueingLoader: loadElement');

    // console.log({identifier: identifier});
    // console.log({element: element});

    element.options = jQuery.extend(
        {},
        this.ajaxDefaults,
        element.options,
        {
          success  : function(data, textStatus, jqXHR) {
            delete this.loading[identifier];
            // console.log('- QueueingLoader: "success" triggered');

            jQuery(this).trigger('success', {identifier : identifier,
                                             context    : element.context,
                                             data       : data});
          },

          error    : function (jqXHR, textStatus, errorThrown) {
            delete this.loading[identifier];
            // console.log('- QueueingLoader: "error" triggered');

            jQuery(this).trigger('error', {identifier : identifier,
                                           context    : element.context,
                                           textStatus : textStatus});
          },

          complete : this.onComplete,

          context  : this
        }
    );

    // console.log({elementOptionsForAjax: element.options});


    this.loading[identifier] = element;

    if(identifier === 'project_types') {
      // console.log('- Queueing Loader: Retrieving project types');
      // // console.log({project_types: ProjectType.query()});
    }

    jQuery.ajax(element.options);
  };

  QueueingLoader.prototype.onComplete = function () {
    // console.log('- QueueingLoader: Complete');

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
      Color,
      Status,
      PlanningElementType,
      HistoricalPlanningElement,
      PlanningElement,
      ProjectType,
      Project,
      ProjectAssociation,
      Reporting,
      User,
      CustomField
    ];
  };

  DataEnhancer.prototype.createObjects = function (data, identifier) {
    var type = DataEnhancer.getBasicType(identifier);

    var i, e, id, map = {};

    if (Array.isArray(data)) {
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
    if (!this.data.hasOwnProperty(ProjectAssociation.identifier)) {
      this.data[ProjectAssociation.identifier] = {};
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
    jQuery.each(this.getElements(Project), function (i, e) {
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

    jQuery.each(dataEnhancer.getElements(Reporting), function (i, reporting) {
      // TODO this somehow didn't make the change to reporting_to_project_id and project_id.
      var project  = dataEnhancer.getElement(Project, reporting.reporting_to_project.id);
      var reporter = dataEnhancer.getElement(Project, reporting.project.id);

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
    if (this.data[User.identifier]) {
      var k, curAttr;
      for (k = 0; k < attributes.length; k += 1) {
        curAttr = attributes[k];
        if (e[curAttr]) {
          e[curAttr.replace(/_id$/, "")] = this.getElement(User,
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

    jQuery.each(dataEnhancer.getElements(Project), function (i, e) {

      dataEnhancer.augmentProjectElementWithUser(e);

      // project_type ← project
      if (e.project_type_id !== undefined) {
        var project_type = dataEnhancer.getElement(ProjectType, e.project_type_id);

        if (project_type) {
          e.project_type = project_type;
        }
      }

      // project ← association → project

      var associations = e[ProjectAssociation.identifier];
      var j, a, other;

      if (Array.isArray(associations)) {
        for (j = 0; j < associations.length; j++) {
          a = associations[j];
          a.timeline = dataEnhancer.timeline;
          a.origin = e;

          other = dataEnhancer.getElement(Project, a.to_project_id);
          if (other) {
            a.project = other;
            dataEnhancer.setElement(
                ProjectAssociation,
                a.id,
                jQuery.extend(Object.create(ProjectAssociation), a));
          }

        }
      }

      // project → parent
      if (e.parent_id) {
        e.parent = dataEnhancer.getElement(Project, e.parent_id);
      }
      delete e.parent_id;
    });
  };

  DataEnhancer.prototype.augmentPlanningElementsWithHistoricalData = function () {
    var dataEnhancer = this;

    jQuery.each(dataEnhancer.getElements(HistoricalPlanningElement), function (i, e) {
      var pe = dataEnhancer.getElement(PlanningElement, e.id);

      if (pe === undefined) {

        // The planning element is in the historical data, but not in
        // the current set of planning elements, i.e. it was deleted
        // in the compared timeframe. We therefore import the deleted
        // element into the planning elements array and set the
        // is_deleted flag.
        e = jQuery.extend(Object.create(PlanningElement), e);
        e.is_deleted = true;
        dataEnhancer.setElement(PlanningElement, e.id, e);
        pe = e;
      }

      pe.historical_element = jQuery.extend(Object.create(PlanningElement), e);
    });

    dataEnhancer.setElementMap(HistoricalPlanningElement, undefined);
  };

  DataEnhancer.prototype.augmentPlanningElementWithStatus = function (pe) {
    // planning_element → planning_element_type
    if (pe.status_id) {
      pe.status = this.getElement(Status,
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
      pe.planning_element_type = this.getElement(PlanningElementType,
                                                 pe.type_id);
    }
    delete pe.type_id;
  };

  DataEnhancer.prototype.augmentPlanningElementWithProject = function (pe) {
    var project = this.getElement(Project, pe.project_id);

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
      var parent = this.getElement(PlanningElement, pe.parent_id);

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

    jQuery.each(dataEnhancer.getElements(PlanningElement), function (i, e) {
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

    jQuery.each(dataEnhancer.getElements(PlanningElement), function (i, e) {
      var pe = dataEnhancer.getElement(PlanningElement, e.id);
      var pet = pe.getPlanningElementType();

      pe.vertical = this.timeline.verticalPlanningElementIds().indexOf(pe.id) !== -1;
    });
  };

  DataEnhancer.prototype.clearUpCustomFieldColumns = function() {
    this.timeline.clearUpCustomFieldColumns();
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
   *        // console.log("'complete' triggered for", this);
   *        // console.log("Loaded data is:", data);
   *      }
   */
  var TimelineLoader = function (timeline, options) {
    this.timelineId   = timeline.id;
    this.options      = options;
    this.data         = {};
    this.loader       = new QueueingLoader(options.ajax_defaults);
    this.dataEnhancer = new DataEnhancer(timeline);

    this.globalPrefix = PathHelper.apiV2;

    this.die = function () {
      this.dataEnhancer.die.apply(this.dataEnhancer, arguments);
    };

    jQuery(this.loader).on('success', jQuery.proxy(this, 'onLoadSuccess'))
                       .on('error',   jQuery.proxy(this, 'onLoadError'))
                       .on('empty',   jQuery.proxy(this, 'onLoadComplete'));
  };

  TimelineLoader.QueueingLoader = QueueingLoader;

  TimelineLoader.prototype.registerTimelineElements = function() {
    // console.log('- TimelineLoader: registerTimelineElements');

    this.registerProjectReportings();
    this.registerGlobalElements();
  };

  TimelineLoader.prototype.load = function () {
    this.loader.load();
  };

  TimelineLoader.prototype.onLoadSuccess = function (e, args) {
    // console.log('- TimelineLoader: onLoadSuccess');
    // console.log({args: args});

    var storeIn  = args.context.storeIn  || args.identifier,
        readFrom = args.context.readFrom || storeIn;

    this.storeData(args.data[readFrom], storeIn);
    this.checkDependencies(args.identifier);
  };

  TimelineLoader.prototype.onLoadError = function (e, args) {
    // console.log({onLoadError: args});

    var storeIn  = args.context.storeIn  || args.identifier;

    console.warn("Error during loading", arguments);

    this.storeData([], storeIn);

    this.checkDependencies(args.identifier);
  };

  TimelineLoader.prototype.onLoadComplete = function (e) {
    // console.log('- TimelineLoader: onLoadComplete');
    // console.log({e: e});

    jQuery(this).trigger('complete', this.dataEnhancer.enhance(this.data));
  };

  TimelineLoader.prototype.registerProjectReportings = function () {
    var projectPrefix = PathHelper.apiV2ProjectsPath() +
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

    this.loader.register(Reporting.identifier,
                         { url : url });
  };

  TimelineLoader.prototype.registerGlobalElements = function () {
    var projectPrefix = PathHelper.apiV2ProjectsPath() +
                        "/" +
                        this.options.project_id;

    this.loader.register(
      Status.identifier,
      { url : this.globalPrefix + '/statuses.json' });
    this.loader.register(
      PlanningElementType.identifier,
      { url : this.globalPrefix + '/planning_element_types.json' });
    this.loader.register(
      Color.identifier,
      { url : this.globalPrefix + '/colors.json' });
    this.loader.register(
      CustomField.identifier,
      { url : projectPrefix + '/planning_element_custom_fields.json' });
    this.loader.register(
      ProjectType.identifier,
      { url : this.globalPrefix + '/project_types.json' });
  };

  TimelineLoader.prototype.registerProjects = function (ids) {
    // console.log('- TimelineLoader: registerProjects');
    // console.log({ids: ids});

    this.inChunks(ids, function (project_ids_of_packet, i) {

      this.loader.register(
          Project.identifier + '_' + i,
          { url : this.globalPrefix +
                  '/projects.json?ids=' +
                  project_ids_of_packet.join(',')},
          { storeIn : Project.identifier }
        );
    });
  };

  TimelineLoader.prototype.registerUsers = function (ids) {
    // console.log('- TimelineLoader: registerUsers');
    // console.log({ids: ids});

    this.inChunks(ids, function (user_ids_of_packet, i) {

      this.loader.register(
          User.identifier + '_' + i,
          { url : this.globalPrefix +
                  '/users.json?ids=' +
                  user_ids_of_packet.join(',')},
          { storeIn : User.identifier }
        );
    });
  };

  TimelineLoader.prototype.provideServerSideFilterHashTypes = function (hash) {
    // console.log('- TimelineLoader: provideServerSideFilterHashTypes');
    // console.log({hash: hash});

    if (this.options.planning_element_types !== undefined) {
      hash.type_id = this.options.planning_element_types;
    }
  };

  TimelineLoader.prototype.provideServerSideFilterHashStatus = function (hash) {
    // console.log('- TimelineLoader: provideServerSideFilterHashStatus');
    // console.log({hash: hash});

    if (this.options.planning_element_status !== undefined) {
      hash.status_id = this.options.planning_element_status;
    }
  };

  TimelineLoader.prototype.provideServerSideFilterHashResponsibles = function (hash) {
    // console.log('- TimelineLoader: provideServerSideFilterHashResponsibles');
    // console.log({hash: hash});

    if (this.options.planning_element_responsibles !== undefined) {
      hash.responsible_id = this.options.planning_element_responsibles;
    }
  };

  TimelineLoader.prototype.provideServerSideFilterHashAssignee = function (hash) {
    if (this.options.planning_element_assignee !== undefined) {
      hash.assigned_to_id = this.options.planning_element_assignee;
    }
  };

  TimelineLoader.prototype.provideServerSideFilterHashCustomFields = function (hash) {
    var custom_fields = this.options.custom_fields, field_id;

    if (custom_fields !== undefined) {
      for (field_id in custom_fields) {
        if (custom_fields.hasOwnProperty(field_id)) {

          var value = custom_fields[field_id];

          if (value && value !== "" && value.length > 0) {
            hash["cf_" + field_id] = value;
          }
        }
      }
    }
  };

  TimelineLoader.prototype.provideServerSideFilterHash = function() {
    // console.log('- TimelineLoader: provideServerSideFilterHash');

    var result = {};
    this.provideServerSideFilterHashTypes(result);
    this.provideServerSideFilterHashResponsibles(result);
    this.provideServerSideFilterHashStatus(result);
    this.provideServerSideFilterHashAssignee(result);
    this.provideServerSideFilterHashCustomFields(result);
    return result;
  };

  TimelineLoader.prototype.registerPlanningElements = function (ids) {
    this.inChunks(ids, function (projectIdsOfPacket, i) {
      var projectPrefix = PathHelper.apiV2ProjectsPath() +
                          "/" +
                          projectIdsOfPacket.join(',');

      var qsb = new FilterQueryStringBuilder(
        this.provideServerSideFilterHash());

      // load current planning elements.
      this.loader.register(
        PlanningElement.identifier + '_' + i,
        { url : qsb.append({timeline: this.timelineId}).build(projectPrefix + '/planning_elements.json') },
        { storeIn: PlanningElement.identifier }
      );

      // load historical planning elements.
      if (this.options.target_time) {
        this.loader.register(
          HistoricalPlanningElement.identifier + '_' + i,
          { url : qsb.append({ at_time: this.options.target_time })
                     .build(projectPrefix + '/planning_elements.json') },
          { storeIn: HistoricalPlanningElement.identifier,
            readFrom: PlanningElement.identifier }
        );
      }
    });
  };


  TimelineLoader.prototype.registerPlanningElementsByID = function (ids) {

    this.inChunks(ids, function (planningElementIdsOfPacket, i) {
      var projectPrefix = PathHelper.apiV2ProjectsPath() +
                          "/" +
                          this.options.project_id;

      // load current planning elements.
      this.loader.register(
        PlanningElement.identifier + '_IDS_' + i,
        { url : projectPrefix +
                '/planning_elements.json?ids=' +
                planningElementIdsOfPacket.join(',')},
        { storeIn: PlanningElement.identifier }
      );
      // load historical planning elements.
      // TODO: load historical PEs here!
      if (this.options.target_time) {
        this.loader.register(
          HistoricalPlanningElement.identifier + '_IDS_' + i,
          { url : projectPrefix +
                  '/planning_elements.json?ids=' +
                  planningElementIdsOfPacket.join(',') },
          { storeIn: HistoricalPlanningElement.identifier,
            readFrom: PlanningElement.identifier }
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
    // console.log('- TimelineLoader: storeData');
    // console.log({data: data, identifier: identifier});

    // console.log({dataToBeExtended: data[identifier]});
    // console.log({dataExtended: this.dataEnhancer.createObjects(data, identifier)});

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
    if (param === Project.identifier ||
        param === PlanningElement.identifier) {

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

    var i, userFields = [], cf = this.data.custom_fields;
    for (var attr in cf) {
      if (cf.hasOwnProperty(attr) && cf[attr].field_format === "user") {
          userFields.push("cf_" + cf[attr].id);
      }
    }

    addUserIDsForElementsByAttribute(results, Timeline.USER_ATTRIBUTES.PLANNING_ELEMENT.concat(userFields), this.data.planning_elements);
    addUserIDsForElementsByAttribute(results, Timeline.USER_ATTRIBUTES.PROJECT, this.data.projects);

    return results;
  };


  TimelineLoader.prototype.getRelevantProjectIdsBasedOnReportings = function () {
    var i,
        relevantProjectIds = [this.options.project_id];

    if (this.doneLoading(Reporting)) {
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

    if (this.doneLoading(Project)) {
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
    return lastLoaded === Reporting.identifier;
  };

  TimelineLoader.prototype.shouldLoadPlanningElements = function (lastLoaded) {

    if (this.doneLoading(Project) &&
        this.doneLoading(Reporting) &&
        this.doneLoading(ProjectType)) {

      this.shouldLoadPlanningElements = function () { return false; };

      return true;
    }
    return false;
  };

  TimelineLoader.prototype.shouldLoadUsers = function (lastLoaded) {
    if (this.doneLoading(Project) &&
        this.doneLoading(Reporting) &&
        this.doneLoading(ProjectType) &&
        this.doneLoading(PlanningElement)) {

      // this will not work for pes from another project (like vertical pes)!
      // but as we do not display users for this data currently,
      // we will not add them yet
      this.shouldLoadUsers = function () { return false; };

      return true;
    }
    return false;
  };

  TimelineLoader.prototype.shouldLoadRemainingPlanningElements = function (lastLoaded) {

    if (this.doneLoading(Project) &&
        this.doneLoading(Reporting) &&
        this.doneLoading(ProjectType) &&
        this.doneLoading(PlanningElement)) {

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
    this.dataEnhancer.clearUpCustomFieldColumns();

    return data;
  };


  var TimelineLoaderService = {
    createTimelineLoader: function(timeline) {
      return new TimelineLoader(timeline, timeline.getTimelineLoaderOptions());
    },
    loadTimelineData: function(timeline) {
      // console.log('- TimelineLoaderService: loadTimelineData');

      var deferred = $q.defer();
      var timelineLoader = null;

      try {
        // prerequisites (3rd party libs)
        timeline.checkPrerequisites();

        timelineLoader = TimelineLoaderService.createTimelineLoader(timeline);
        timelineLoader.registerTimelineElements();

        jQuery(timelineLoader).on('complete', function(e, data) {
          angular.extend(timeline, data);
          deferred.resolve(timeline);
        });

        timeline.safetyHook = window.setTimeout(function() {
          deferred.reject(I18n.t('js.timelines.errors.report_timeout'));
        }, Timeline.LOAD_ERROR_TIMEOUT);

        timelineLoader.load();

      } catch (e) {
        deferred.reject(e);
      }
      return deferred.promise;
    }
  };

  return TimelineLoaderService;
};
