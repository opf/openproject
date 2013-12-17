window.backbone_app.models.PlanningElement = Backbone.Model.extend({

  url: function(){
    return "/api/v2/projects/" + this.get('project_id') + "/planning_elements/" + this.get('id');
  },

  planning_element_type: {
    is_milestone: false,
    in_aggregation: true,
  },

  // TODO RS: Look into if this is possible/sensible ie are sub-elements
  // returned in the server response json?
  getSubElements: function(){
    return [];
  },

  // TODO RS: Just return false for now but really need to look if we have
  // nested elements.
  hasChildren: function() {
    return false;
  },

  /* Dummy method since we don't have backbone planning element types yet */
  getPlanningElementType: function(){
    return this.planning_element_type;
  },

  /* Methods required by TreeNode when rendering and generally for the current setup.
     Once I've got comfortable with how things work I'll start messing it up:D */
  identifier: 'planning_elements',

  is: function(t) {
    return this.identifier === t.identifier;
  },

  /* TODO RS: If these cannot be determined by what is returned from the
     server then we're going to have to set a flag on the model from the
     view somehow. */
  filteredOut: function(){
    return false;
  },

  hide: function(){
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

  // NOTE RS: Changed because I'm not dealing with alternate/historical stuff
  hasAlternateDates: function() {
    return false;
  },

  start: function() {
    var pet = this.getPlanningElementType();
    //if we have got a milestone w/o a start date but with an end date, just set them the same.
    if (this.get('start_date') === undefined && this.get('due_date') !== undefined && pet && pet.is_milestone) {
      this.set({
        start_date: this.get('due_date')
      });
    }
    if (this.start_date_object === undefined && this.get('start_date') !== undefined) {
      this.set({
        start_date_object: Date.parse(this.get('start_date'))
      });
    }
    return this.get('start_date_object');
  },

  // NOTE RS: Changed because I'm not dealing with alternate/historical stuff
  alternate_start: function() {
    return this.start();
  },

  end: function() {
    var pet = this.getPlanningElementType();
    //if we have got a milestone w/o a start date but with an end date, just set them the same.
    if (this.get('due_date') === undefined && this.get('start_date') !== undefined && pet && pet.is_milestone) {
      this.set({
        due_date: this.get('start_date')
      });
    }
    if (this.due_date_object === undefined && this.get('due_date') !== undefined) {
      this.set({
        due_date_object: Date.parse(this.get('due_date'))
      });
    }
    return this.get('due_date_object');
  },

  // NOTE RS: Changed because I'm not dealing with alternate/historical stuff
  alternate_end: function() {
    return this.end();
  },

  getHorizontalBounds: function(scale, absolute_beginning, milestone, ui_utils) {
    return this.getHorizontalBoundsForDates(
      scale,
      absolute_beginning,
      this.start(),
      this.end(),
      milestone,
      ui_utils
    );
  },

  getAlternateHorizontalBounds: function(scale, absolute_beginning, milestone, ui_utils) {
    return this.getHorizontalBoundsForDates(
      scale,
      absolute_beginning,
      this.alternate_start(),
      this.alternate_end(),
      milestone,
      ui_utils
    );
  },

  getHorizontalBoundsForDates: function(scale, absolute_beginning, start, end, milestone, ui_utils) {

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
    var x = ui_utils.getDaysBetween(absolute_beginning, start) * scale.day;
    var w = (ui_utils.getDaysBetween(start, end) + 1) * scale.day;

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

  getColor: function () {
    // TODO RS: Commented this out for demo
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
});