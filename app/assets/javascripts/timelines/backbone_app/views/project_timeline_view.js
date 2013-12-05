window.backbone_app.views.ProjectTimelineView = window.backbone_app.views.BaseView.extend({
  tagName: "div",

  className: "project-timeline",

  events: {},

  parent: function(){
    return this.options.parent;
  },

  initialize: function(options){
    // We require here the timeline, the node, the raphael drawing element
    this.options = options;
  },

  render: function() {
    console.log('rendering project planning elements on the timeline');
    // NOTE: This render method is responsible for creating all the sub-planning-element
    // views and rendering them. This code has been moved here from the old Project element
    // render methed and reduced to only show planning elements. Also I'm ignoring planning
    // element types because I haven't got them in backbone yet.
    var self = this;
    var node = this.options.node;
    if (node.isExpanded()) {
      return false;
    }

    var timeline = this.options.timeline;
    var scale = timeline.getScale();
    var beginning = timeline.getBeginning();
    var milestones, others;
    var planning_elements = this.options.planning_elements;

    // draw all planning elements that should be seen in an
    // aggregation. limited to one level.

    // TODO RS: will need to start moving all of the current model rendering shit to the views:/
    var pes = jQuery.grep(planning_elements, function(e) {
      return e.start() !== undefined &&
             e.end() !== undefined &&
             e.planning_element_type.in_aggregation;
    });

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

    // The label_spaces object will contain available spaces per
    // planning element. There may be many.
    var label_spaces = {};

    var render = function(i, e) {
      var node = jQuery.extend({}, dummy_node, {
        getData: function() { return e; }
      });
      // Note: Old render call on model
      // e.render(node, true, label_spaces[i]);
      // e.renderForeground(node, true, label_spaces[i]);

      // Note: New backbone stuff
      var pe_view = new window.backbone_app.views.PlanningElementTimelineView(e, {
        timeline: self.options.timeline,
        paper: self.options.paper,
        node: node,
        in_aggregation: false, // TODO RS: What's this for?
        label_space: false // TODO RS: use label_spaces[i] once it's working
      });
      pe_view.render();
    };

    var visible_in_aggregation = function(e, i) {
      var pet = e.getPlanningElementType();
      return !e.filteredOut() && pet && pet.in_aggregation;
    };

    // divide into milestones and others.
    milestones = jQuery.grep(pes, is_milestone);
    others = jQuery.grep(pes, is_milestone, true);

    // join others with milestones, and remove all that should be filtered.
    pes = jQuery.grep(others.concat(milestones), visible_in_aggregation);

    // Outer loop to calculate best label space for each planning
    // element. Here, we initialize possible spaces by registering the
    // whole element as the single space for a label.

    // jQuery.each(pes, function(i, e) {

    //   var b = e.getHorizontalBounds(scale, beginning);
    //   label_spaces[i] = [b];

    //   // find all pes above the one we're traversing.
    //   var passed_self = false;
    //   var pes_to_traverse = jQuery.grep(pes, function(f) {
    //     return passed_self || (e === f) ? passed_self = true : false;
    //   });

    //   // Now, for every other element , shorten the available spaces or splice them.
    //   jQuery.each(pes_to_traverse, function(j, f) {
    //     var k, cb = f.getHorizontalBounds(scale, beginning, is_milestone(f));

    //     // do not shorten if I am looking at myself.
    //     if (e === f) {
    //       return;
    //     }

    //     // do not shorten if current element is not a milestone and
    //     // begins before me.
    //     if (!is_milestone(f) && cb.x < b.x) {
    //       return;
    //     }

    //     // do not shorten if both are milestones and current begins before me.
    //     if (is_milestone(f) && is_milestone(e) && cb.x < b.x) {
    //       return;
    //     }

    //     // do not shorten if I am a milestone and current element is not.
    //     if (is_milestone(e) && !is_milestone(f)) {
    //       return;
    //     }

    //     // iterate over actual spaces left for shortening or splicing.
    //     var spaces = label_spaces[i];
    //     for (k = 0; k < spaces.length; k++) {
    //       var space = spaces[k];

    //       // b  eeeeeeee
    //       //cb       fffffffffff

    //       // current element lies after me,
    //       var rightSideOverlap = cb.x > space.x &&
    //               // but I do end after its start.
    //               cb.x < space.end();

    //       // b           eeeeeeeeeee
    //       //cb    ffffffffffff

    //       // current element lies before me
    //       var leftSideOverlap = cb.end() < space.end() &&
    //                 // but I start before current elements end.
    //                 cb.end() > space.x;

    //       if ((cb.x <= space.x && cb.end() >= space.end()) &&
    //           (label_spaces[i].length > 0)) {
    //         if (label_spaces[i].length === 1) {
    //           label_spaces[i][0].w = 0;
    //         } else {
    //           label_spaces[i].splice(k, 1);
    //         }
    //       }

    //       //  fffffffeeeeeeeeeeeeffffffffff

    //       if (rightSideOverlap && leftSideOverlap) {

    //         // if current planning element is completely enclosed
    //         // in the current space, split the space into two, and
    //         // reiterate. splitting happens by splicing the array at
    //         // position i.
    //         label_spaces[i].splice(k, 1,
    //           {'x': space.x,
    //            'w': cb.x - space.x, end: space.end},
    //           {'x': cb.end(),
    //            'w': space.end() - cb.end(), end: space.end});

    //       } else if (rightSideOverlap) {

    //         // if current planning element (f) starts before the one
    //         // current space ends, adjust the width of the space.
    //         space.w = Math.min(space.end(), cb.x) - space.x;

    //       } else if (leftSideOverlap) {

    //         // if current planning element (f) ends after the current
    //         // space starts, adjust the beginning of the space.
    //         // we also need to modify the width because we want to
    //         // keep the end at the same position.
    //         var oldStart = space.x;
    //         space.x = Math.max(space.x, cb.end());
    //         space.w -= (space.x - oldStart);
    //       }
    //     }
    //   });

    //   // after all possible label spaces for the given element are
    //   // evaluated, select the widest.
    //   b = label_spaces[i].shift();
    //   jQuery.each(label_spaces[i], function(i, e) {
    //     if (e.w > b.w) {
    //       b = e;
    //     }
    //   });
    //   label_spaces[i] = b;
    // });

    // jQuery.each(others, render);
    // jQuery.each(milestones, render);
    jQuery.each(pes, render);
  },
});