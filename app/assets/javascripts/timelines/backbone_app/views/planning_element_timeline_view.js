window.backbone_app.views.PlanningElementTimelineView = window.backbone_app.views.BaseView.extend({
  tagName: "div",

  className: "planning-element",

  events: {},

  parent: function(){
    return this.options.parent;
  },

  initialize: function(model, options){
    // We require here the timeline, the node, the raphael drawing element
    this.model = model;
    this.options = options;
    this.model.bind("change", _.bind(this.modelChanged, this));
  },

  /*
    TODO RS: There might be a nicer way to bubble up the redraw requirement to the
    parent views. I should look into this.
  */
  modelChanged: function(){
    this.options.parent_view.redrawRequired();
  },

  /*
    I wanted to get this as a backbone event but it's much easier to just let Raphael
    handle it as we can pass the model back that way.
  */
  showEditMenu: function(pe, data){
    jQuery('.edit-pe').remove();
    var edit_view = new window.backbone_app.views.EditPlanningElementView(pe, data).render();
  },

  /* These are some methods taken from timelines.js because i REALLY don't
     want the model objects having timelines as a parent. */
  ui_utils: function() {
    return {
      getDaysBetween: function(a, b) {
        // some meat around date calculations that will be floored out again
        // later. this hopefully takes care of floating point imprecisions
        // and possible leap seconds, as we're only interested in days.
        var da = a - 1000 * 60 * 60 * 4;
        var db = b - 1000 * 60 * 60 * (-4);
        return Math.floor((db - da) / (1000 * 60 * 60 * 24));
      },
    }
  },

  render: function(){
    console.log('rendering planning element on the timeline');
    this.renderMain();
    // this.renderForeground();
  },

  renderMain: function() {
    var ui_utils = this.ui_utils();
    var timeline = this.options.timeline;
    var paper = this.options.paper;
    var node = this.options.node;
    var in_aggregation = this.options.in_aggregation;
    var label_space = this.options.label_space;
    var scale = timeline.getScale();
    var beginning = timeline.getBeginning();
    var elements = [];
    var pet = this.model.getPlanningElementType();
    var self = this;
    var color, text, x, y, textColor;
    var bounds = this.model.getHorizontalBounds(scale, beginning, false, ui_utils);
    var left = bounds.x;
    var width = bounds.w;
    var alternate_bounds = this.model.getAlternateHorizontalBounds(scale, beginning, false, ui_utils);
    var alternate_left = alternate_bounds.x;
    var alternate_width = alternate_bounds.w;
    var hover_left = left;
    var hover_width = width;
    var element = node.getDOMElement();
    var captionElements = [];
    var label;
    var deleted = false //true && this.is_deleted;
    var comparison_offset = deleted ? 0 : Timeline.DEFAULT_COMPARISON_OFFSET;
    var strokeColor = Timeline.DEFAULT_STROKE_COLOR;
    // var historical = this.historical();

    var has_both_dates = this.model.hasBothDates();
    var has_one_date = this.model.hasOneDate();
    var has_start_date = this.model.hasStartDate();

    if (in_aggregation && label_space !== undefined) {
      hover_left = label_space.x + Timeline.HOVER_THRESHOLD;
      hover_width = label_space.w - 2 * Timeline.HOVER_THRESHOLD;
    }

    if (in_aggregation && !has_both_dates) {
      return;
    }

    var has_alternative = this.model.hasAlternateDates();
    var could_have_been_milestone = (this.model.alternate_start === this.model.alternate_end);

    var height, top;

    // if (historical.hasOneDate()) {
    //   // ╭─────────────────────────────────────────────────────────╮
    //   // │ Rendering of historical data. Use default planning      │
    //   // │ element appearance, only use milestones when the        │
    //   // │ element is currently a milestone and the historical     │
    //   // │ data has equal start and end dates.                     │
    //   // ╰─────────────────────────────────────────────────────────╯
    //   color = this.historical().getColor();

    //   if (!historical.hasBothDates()) {
    //     strokeColor = 'none';
    //   }

    //   //TODO: fix for work units w/o start/end date
    //   if (!in_aggregation && has_alternative) {
    //     if (pet && pet.is_milestone && could_have_been_milestone) {

    //       height = scale.height - 1; //6px makes the element a little smaller.
    //       top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

    //       paper.path(
    //         timeline.psub('M#{x} #{y}h#{w}l#{d} #{d}l-#{d} #{d}H#{x}l-#{d} -#{d}l#{d} -#{d}Z', {
    //           x: alternate_left + scale.day / 2,
    //           y: top - comparison_offset,
    //           w: alternate_width - scale.day,
    //           d: height / 2 // diamond corner width.
    //         })
    //       ).attr({
    //         'fill': color, // Timeline.DEFAULT_FILL_COLOR_IN_COMPARISONS,
    //         'opacity': 0.33,
    //         'stroke': Timeline.DEFAULT_STROKE_COLOR_IN_COMPARISONS,
    //         'stroke-dasharray': Timeline.DEFAULT_STROKE_DASHARRAY_IN_COMPARISONS
    //       });

    //     } else {

    //       height = scale.height - 6; //6px makes the element a little smaller.
    //       top = (timeline.getRelativeVerticalOffset(element) + timeline.getRelativeVerticalBottomOffset(element)) / 2 - height / 2;

    //       paper.rect(
    //         alternate_left,
    //         top - comparison_offset, // 8px margin-top
    //         alternate_width,
    //         height,           // 8px  margin-bottom
    //         4                           // round corners
    //       ).attr({
    //         'fill': color, // Timeline.DEFAULT_FILL_COLOR_IN_COMPARISONS,
    //         'opacity': 0.33,
    //         'stroke': Timeline.DEFAULT_STROKE_COLOR_IN_COMPARISONS,
    //         'stroke-dasharray': Timeline.DEFAULT_STROKE_DASHARRAY_IN_COMPARISONS
    //       });
    //     }
    //   }
    // }

    // only render planning elements that have
    // either a start or an end date.
    // TODO RS: Current location
    if (has_one_date) {
      color = this.model.getColor();

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

      } else if (!deleted && !in_aggregation && this.model.hasChildren() && node.isExpanded()) {

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

        var rect = paper.rect(
          left,
          top,
          width,
          height,
          4                           // round corners
        ).attr({
          'fill': color,
          'stroke': strokeColor,
          'data-blabla': "asdf"
        }).data('planning-element', node.getData())
        .click(function(e){
          self.showEditMenu(this.data('planning-element'),
            { top: e.clientY, left: e.clientX });
        });
      }
    }
  },

  /*
  renderForeground: function (node, in_aggregation, label_space) {
    // TODO RS: Fix it all up there...
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
    // │ Labels for rendered elements, either in aggregartion    │
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

          // place a white rect below the label.
          captionElements.push(
            timeline.paper.rect(
              -3,
              -12,
              textWidth + 6,
              15,
              4.5
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
              textWidth -   // text width
              4;                                         // small border from the right
          }

          textColor = timeline.getLimunanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
            Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;
        } else {

          // text inside planning element
          x = left + width * 0.5 +                             // center of the planning element
              textWidth * (-0.5); // half of text width

          textColor = timeline.getLimunanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
            Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;
        }

        label.attr({
          'fill': textColor,
          'text-anchor': "start",
          'stroke': 'none'
        });

        if (captionElements[0]) {
          label.insertAfter(captionElements[0]);
        }

        captionElements.push(label);

        jQuery.each(captionElements, function(i, e) {
          e.translate(x, y);
        });

      } else if (label_space.w > Timeline.PE_TEXT_AGGREGATED_LABEL_WIDTH_THRESHOLD) {

        textColor = timeline.getLimunanceFor(color) > Timeline.PE_LUMINANCE_THRESHOLD ?
                    Timeline.PE_DARK_TEXT_COLOR : Timeline.PE_LIGHT_TEXT_COLOR;

        var text = this.subject;
        label = timeline.paper.text(0, 0, text);
        label.attr({
          'font-size': 12,
          'fill': textColor,
          'stroke': 'none'
        });

        x = label_space.x + label_space.w/2;
        y -= 4;

        while (text.length > 0 && label.getBBox().width > label_space.w) {
          text = text.slice(0, -1);
          label.attr({ 'text': text });
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
  }, */
});