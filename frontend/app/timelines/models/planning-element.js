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

module.exports = function(PathHelper) {

  PlanningElement = {
    objectType: 'PlanningElement',
    identifier: 'planning_elements',

    is: function(t) {
      if (t === undefined) return false;
      return PlanningElement.identifier === t.identifier;
    },
    hide: function () {
      return false;
    },
    filteredOut: function() {
      var filtered = this.filteredOutForProjectFilter();
      this.filteredOut = function() { return filtered; };
      return filtered;
    },
    inTimeFrame: function () {
      return this.timeline.inTimeFilter(this.start(), this.end());
    },
    filteredOutForProjectFilter: function() {
      return this.project.filteredOut();
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
    getResponsibleName: function()  {
      if (this.responsible && this.responsible.name) {
        return this.responsible.name;
      }
    },
    getAssignedName: function () {
      if (this.assigned_to && this.assigned_to.name) {
        return this.assigned_to.name;
      }
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
    getTypeName: function () {
      var pet = this.getPlanningElementType();
      if (pet) {
        return pet.name;
      }
    },
    getStatusName: function () {
      if (this.status) {
        return this.status.name;
      }
    },
    getProjectName: function () {
      if (this.project) {
        return this.project.name;
      }
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
      if (this.start_date === undefined && this.due_date !== undefined && pet && pet.is_milestone) {
        this.start_date = this.due_date;
      }
      if (this.start_date_object === undefined && this.start_date !== undefined) {
        this.start_date_object = moment(this.start_date).toDate();
      }
      return this.start_date_object;
    },
    end: function() {
      var pet = this.getPlanningElementType();
      //if we have got a milestone w/o a start date but with an end date, just set them the same.
      if (this.due_date === undefined && this.start_date !== undefined && pet && pet.is_milestone) {
        this.due_date = this.start_date;
      }
      if (this.due_date_object=== undefined && this.due_date !== undefined) {
        this.due_date_object = moment(this.due_date).toDate();
      }
      return this.due_date_object;
    },
    getAttribute: function (val) {
      if (typeof this[val] === "function") {
        return this[val]();
      }

      return this[val];
    },
    does_historical_differ: function (val) {
      if (!this.has_historical()) {
        return false;
      }

      return this.historical().getAttribute(val) !== this.getAttribute(val);
    },
    has_historical: function () {
      return this.historical_element !== undefined;
    },
    historical: function () {
      return this.historical_element || Object.create(PlanningElement);
    },
    alternate_start: function() {
      return this.historical().start();
    },
    alternate_end: function() {
      return this.historical().end();
    },
    getSubElements: function() {
      return this.getChildren();
    },
    hasAlternateDates: function() {
      return (this.does_historical_differ("start_date") ||
              this.does_historical_differ("due_date") ||
              this.is_deleted);
    },
    isDeleted: function() {
      return true && this.is_deleted;
    },
    isNewlyAdded: function() {
      return (this.timeline.isComparing() &&
              !this.has_historical());
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
      return PathHelper.staticBase + "/work_packages/" + this.id;
    },
    getColor: function () {
      // if there is a color for this planning element type, use it.
      // use it also for planning elements w/ children. if there are
      // children but no planning element type, use the default color
      // for planning element parents. if there is no planning element
      // type and there are no children, use a default color.
      var pet = this.getPlanningElementType();
      var paper = this.timeline.getPaper();
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
          var noEndDateGradient = jQuery('#noEndDateGradient_' + pet.id);
          if (noEndDateGradient.length == 0) {
            noEndDateGradient = paper.gradient(
                'noEndDateGradient_' + pet.id,
                [
                  {offset: '5%', 'stop-color': color, 'stop-opacity': '1'},
                  {offset: '95%', 'stop-color': '#ffffff', 'stop-opacity': '0'}
                ]
            );
          }

          color = 'url(#noEndDateGradient_' + pet.id + ')';
        } else {
          var noStartDateGradient = jQuery('#noStartDateGradient_' + pet.id);
          if (noStartDateGradient.length == 0) {
            noStartDateGradient = paper.gradient(
                'noStartDateGradient_' + pet.id,
                [
                  {offset: '5%', 'stop-color': '#ffffff', 'stop-opacity': '0'},
                  {offset:'95%', 'stop-color': color, 'stop-opacity': '1'}
                ]
            );
          }

          color = 'url(#noStartDateGradient_' + pet.id + ')';
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
      var captionElement;
      var label;
      var deleted = true && this.is_deleted;
      var comparison_offset = deleted ? 0 : Timeline.DEFAULT_COMPARISON_OFFSET;
      var strokeColor = Timeline.DEFAULT_STROKE_COLOR;
      var historical = this.historical();

      var has_both_dates = this.hasBothDates();
      var has_one_date = this.hasOneDate();
      var has_start_date = this.hasStartDate();

      if (in_aggregation && label_space !== undefined) {
        hover_left = label_space.x + Timeline.HOVER_THRESHOLD;
        hover_width = label_space.w - 2 * Timeline.HOVER_THRESHOLD;
      }

      if (in_aggregation && !has_both_dates) {
        return;
      }

      var has_alternative = this.hasAlternateDates();
      var could_have_been_milestone = (this.alternate_start === this.alternate_end);

      var height, top;

      if (historical.hasOneDate()) {
        // ╭─────────────────────────────────────────────────────────╮
        // │ Rendering of historical data. Use default planning      │
        // │ element appearance, only use milestones when the        │
        // │ element is currently a milestone and the historical     │
        // │ data has equal start and end dates.                     │
        // ╰─────────────────────────────────────────────────────────╯
        color = this.historical().getColor();

        if (!historical.hasBothDates()) {
          strokeColor = 'none';
        }

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
      }

      // only render planning elements that have
      // either a start or an end date.
      if (has_one_date) {
        color = this.getColor();

        if (!has_both_dates) {
          strokeColor = 'none';
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
      var captionElement;
      var label, textWidth;
      var deleted = true && this.is_deleted;
      var comparison_offset = deleted ? 0 : Timeline.DEFAULT_COMPARISON_OFFSET;

      var has_both_dates = this.hasBothDates();
      var has_one_date = this.hasOneDate();
      var has_start_date = this.hasStartDate();

      if (in_aggregation && label_space !== undefined) {
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
      // │ Labels for rendered elements, either in aggregation     │
      // │ or out of aggregation, inside of elements or outside.   │
      // ╰─────────────────────────────────────────────────────────╯

      height = scale.height - 6; //6px makes the element a little smaller.
      top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

      y = top + 11;

      if (has_one_date) {
        if (!in_aggregation) {

          // text rendering in planning elements outside of aggregations
          label = timeline.paper.text(0, -5, this.subject);
          label.attr({
            'font-size': 12
          });

          textWidth = label.getBBox().width;

          // if this is an expanded planning element w/ children, or if
          // the text would not fit:
          if (this.hasChildren() && node.isExpanded() ||
              textWidth > width - Timeline.PE_TEXT_INSIDE_PADDING) {

            // text outside planning element
            x = left + width + Timeline.PE_TEXT_OUTSIDE_PADDING;

            if (this.hasChildren()) {
              x += Timeline.PE_TEXT_ADDITIONAL_OUTSIDE_PADDING_WHEN_EXPANDED_WITH_CHILDREN;
            }

            if (pet && pet.is_milestone) {
              x += Timeline.PE_TEXT_ADDITIONAL_OUTSIDE_PADDING_WHEN_MILESTONE;
            }

            textColor = Timeline.PE_DEFAULT_TEXT_COLOR;

            // place a white rect below the label.
            captionElement = timeline.paper.rect(
              x-3,
              y-12,
              textWidth + 6,
              15,
              4.5
            ).attr({
              'fill': '#ffffff',
              'opacity': 0.5,
              'stroke': 'none'
            });

            captionElement.insertAfter(label);

          } else if (!has_both_dates) {
            // text inside planning element
            if (has_start_date) {
              x = left + 4;                                // left of the WU
            } else {
              x = left + width -                           // right of the WU
                textWidth -   // text width
                4;                                         // small border from the right
            }

            textColor = timeline.getLuminanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
              Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;
          } else {

            // text inside planning element
            x = left + width * 0.5 +                             // center of the planning element
                textWidth * (-0.5); // half of text width

            textColor = timeline.getLuminanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
              Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;
          }

          label.attr({
            'fill': textColor,
            'text-anchor': "start",
            'stroke': 'none'
          });

          // position label
          label.translate(x,y);

        } else if (label_space.w > Timeline.PE_TEXT_AGGREGATED_LABEL_WIDTH_THRESHOLD) {
          // Elements in aggregation
          textColor = timeline.getLuminanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
                      Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;

          text = this.subject;
          label = timeline.paper.text(0, 0, text);
          label.attr({
            'font-size': 12,
            'text-anchor': 'middle',
            'fill': textColor,
            'stroke': 'none'
          });

          x = label_space.x + label_space.w/2;

          // fit text to label space
          while (text.length > 0 && label.getBBox().width + Timeline.PE_TEXT_INSIDE_PADDING / 2 > label_space.w) {
            text = text.slice(0, -1);
            label.textContent = text;
          }

          label.translate(x, y);
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

      var hoverElement;

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

          hoverElement = paper.rect(
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

          hoverElement = paper.rect(
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
  };

  return PlanningElement;
};
