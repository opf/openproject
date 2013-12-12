timelinesApp.factory('PlanningElement', ['$resource', 'APIDefaults', function($resource, APIDefaults) {

  PlanningElement = $resource(
    APIDefaults.apiPrefix + APIDefaults.projectPath + '/planning_elements/:id.json',
    {projectId: '@projectId', id: '@planningElementId'},
    {
      get: {
        // Explicit specification needed because of API reponse format
        method: 'GET',
        transformResponse: function(data) {
          return new PlanningElement(angular.fromJson(data).planning_element);
        }
      },
      query: {
        method: 'GET',
        isArray: true,
        transformResponse: function(data) {
          // Angular resource expects a json array and would return json
          // Here we fetch the results and map them to PlanningElement resources
          wrapped = angular.fromJson(data);
          angular.forEach(wrapped.planning_elements, function(item, idx) {
            wrapped.planning_elements[idx] = new PlanningElement(item);
          });
          return wrapped.planning_elements;
        }
      }
    });

  PlanningElement.prototype.is = function(t) {
    return this.identifier === t.identifier;
  };
  PlanningElement.prototype.hide = function () {
    return false;
  };
  PlanningElement.prototype.filteredOut = function() {
    var filtered = this.filteredOutForProjectFilter();
    this.filteredOut = function() { return filtered; };
    return filtered;
  };
  PlanningElement.prototype.inTimeFrame = function () {
    return this.timeline.inTimeFilter(this.start(), this.end());
  };
  PlanningElement.prototype.filteredOutForProjectFilter = function() {
    return this.project.filteredOut();
  };
  PlanningElement.prototype.all = function(timeline) {
    // collect all planning elements
    var r = timeline.planning_elements;
    var result = [];
    for (var key in r) {
      if (r.hasOwnProperty(key)) {
        result.push(r[key]);
      }
    }
    return result;
  };
  PlanningElement.prototype.getProject = function() {
    return (this.project !== undefined) ? this.project : null;
  };
  PlanningElement.prototype.getPlanningElementType = function() {
    return (this.planning_element_type !== undefined) ?
      this.planning_element_type : null;
  };
  PlanningElement.prototype.getResponsible = function() {
    return (this.responsible !== undefined) ? this.responsible : null;
  };
  PlanningElement.prototype.getResponsibleName = function()  {
    if (this.responsible && this.responsible.name) {
      return this.responsible.name;
    }
  };
  PlanningElement.prototype.getAssignedName = function () {
    if (this.assigned_to && this.assigned_to.name) {
      return this.assigned_to.name;
    }
  };
  PlanningElement.prototype.getParent = function() {
    return (this.parent !== undefined) ? this.parent : null;
  };
  PlanningElement.prototype.getChildren = function() {
    if (!this.planning_elements) {
      return [];
    }
    if (!this.sorted) {
      this.sort('planning_elements');
      this.sorted = true;
    }
    return this.planning_elements;
  };
  PlanningElement.prototype.hasChildren = function() {
    return this.getChildren().length > 0;
  };
  PlanningElement.prototype.getTypeName = function () {
    var pet = this.getPlanningElementType();
    if (pet) {
      return pet.name;
    }
  };
  PlanningElement.prototype.getStatusName = function () {
    if (this.status) {
      return this.status.name;
    }
  };
  PlanningElement.prototype.getProjectName = function () {
    if (this.project) {
      return this.project.name;
    }
  };
  PlanningElement.prototype.sort = function(field) {
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
  };
  PlanningElement.prototype.start = function() {
    var pet = this.getPlanningElementType();
    //if we have got a milestone w/o a start date but with an end date, just set them the same.
    if (this.start_date === undefined && this.due_date !== undefined && pet && pet.is_milestone) {
      this.start_date = this.due_date;
    }
    if (this.start_date_object === undefined && this.start_date !== undefined) {
      this.start_date_object = Date.parse(this.start_date);
    }
    return this.start_date_object;
  };
  PlanningElement.prototype.end = function() {
    var pet = this.getPlanningElementType();
    //if we have got a milestone w/o a start date but with an end date, just set them the same.
    if (this.due_date === undefined && this.start_date !== undefined && pet && pet.is_milestone) {
      this.due_date = this.start_date;
    }
    if (this.due_date_object=== undefined && this.due_date !== undefined) {
      this.due_date_object = Date.parse(this.due_date);
    }
    return this.due_date_object;
  };
  PlanningElement.prototype.getAttribute = function (val) {
    if (typeof this[val] === "function") {
      return this[val]();
    }

    return this[val];
  };
  PlanningElement.prototype.does_historical_differ = function (val) {
    if (!this.has_historical()) {
      return false;
    }

    return this.historical().getAttribute(val) !== this.getAttribute(val);
  };
  PlanningElement.prototype.has_historical = function () {
    return this.historical_element !== undefined;
  };
  PlanningElement.prototype.historical = function () {
    return this.historical_element || Object.create(Timeline.PlanningElement);
  };
  PlanningElement.prototype.alternate_start = function() {
    return this.historical().start();
  };
  PlanningElement.prototype.alternate_end = function() {
    return this.historical().end();
  };
  PlanningElement.prototype.getSubElements = function() {
    return this.getChildren();
  };
  PlanningElement.prototype.hasAlternateDates = function() {
    return (this.does_historical_differ("start_date") ||
            this.does_historical_differ("end_date") ||
            this.is_deleted);
  };
  PlanningElement.prototype.isDeleted = function() {
    return true && this.is_deleted;
  };
  PlanningElement.prototype.isNewlyAdded = function() {
    return (this.timeline.isComparing() &&
            !this.has_historical());
  };
  PlanningElement.prototype.getAlternateHorizontalBounds = function(scale, absolute_beginning, milestone) {
    return this.getHorizontalBoundsForDates(
      scale,
      absolute_beginning,
      this.alternate_start(),
      this.alternate_end(),
      milestone
    );
  };
  PlanningElement.prototype.getHorizontalBounds = function(scale, absolute_beginning, milestone) {
    return this.getHorizontalBoundsForDates(
      scale,
      absolute_beginning,
      this.start(),
      this.end(),
      milestone
    );
  };
  PlanningElement.prototype.hasStartDate = function () {
    if (this.start()) {
      return true;
    }

    return false;
  };
  PlanningElement.prototype.hasEndDate = function () {
    if (this.end()) {
      return true;
    }

    return false;
  };
  PlanningElement.prototype.hasBothDates = function () {
    if (this.start() && this.end()) {
      return true;
    }

    return false;
  };
  PlanningElement.prototype.hasOneDate = function () {
    if (this.start() || this.end()) {
      return true;
    }

    return false;
  };
  PlanningElement.prototype.getHorizontalBoundsForDates = function(scale, absolute_beginning, start, end, milestone) {
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
  };
  PlanningElement.prototype.getUrl = function() {
    var options = this.timeline.options;
    var url = options.url_prefix;

    url += "/work_packages/";
    url += this.id;

    return url;
  };
  PlanningElement.prototype.getColor = function () {
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
  };

  return PlanningElement;
}]);
