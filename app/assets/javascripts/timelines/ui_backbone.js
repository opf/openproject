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

//UI?
jQuery.extend(Timeline, {

  completeUIBackbone: function(tree, ui_root) {
    var timeline = this;

    // construct tree on left-hand-side.
    this.rebuildTreeBackbone(tree, ui_root);

    // lift the curtain, paper otherwise doesn't show w/ VML.
    jQuery('.timeline').removeClass('tl-under-construction');
    this.paper = new Raphael(ui_root.get()[0], 640, 480);

    // TODO RS: All of this causes re-renders which is a pain right now

    // perform some zooming. if there is a zoom level stored with the
    // report, zoom to it. otherwise, zoom out. this also constructs
    // timeline graph.
    if (this.options.zoom_factor &&
        this.options.zoom_factor.length === 1) {

      this.zoomBackbone(
        this.pnum(this.options.zoom_factor[0])
      );

    } else {
      // this.zoomOut();
    }

    // // perform initial outline expansion.
    // if (this.options.initial_outline_expansion &&
    //     this.options.initial_outline_expansion.length === 1) {

    //   this.expandTo(
    //     this.pnum(this.options.initial_outline_expansion[0])
    //   );
    // }

    // zooming and initial outline expansion have consequences in the
    // select inputs in the toolbar.
    // this.updateToolbar();

    // this.getChart().scroll(function() {
    //   timeline.adjustTooltip();
    // });

    // jQuery(window).scroll(function() {
    //   timeline.adjustTooltip();
    // });
  },

  getTree: function(){
    return this.tree;
  },

  zoomBackbone: function(index) {
    if (index === undefined) {
      index = this.zoomIndex;
    }
    index = Math.max(Math.min(this.ZOOM_SCALES.length - 1, index), 0);
    this.zoomIndex = index;
    var scale = Timeline.ZOOM_CONFIGURATIONS[Timeline.ZOOM_SCALES[index]].scale;
    this.setScale(scale);
    this.resetWidth();
    this.triggerResize();
    // rebuildAll seems to fuck everything up but i'm not sure why
    // this.rebuildAllBackbone();
  },

  rebuildAllBackbone: function() {
    var timeline = this;
    var root = timeline.getUiRoot();
    var tree = timeline.getTree();

    delete this.table_offset;

    window.clearTimeout(this.rebuildTimeout);
    this.rebuildTimeout = timeline.defer(function() {
      timeline.rebuildTreeBackbone(tree, root);

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
        timeline.rebuildGraphBackbone(tree, root);
      } else {
        var chart = timeline.getUiRoot().find('.tl-chart');
        chart.css({ display: 'none'});
      }
      timeline.adjustScrollingForChangedContent();
    });
  },

  /* TODO RS:
       This needs to change a lot...
       This should all be made with various templates and not constructed on the fly

  */
  rebuildTreeBackbone: function(tree, ui_root) {
    var where = ui_root.find('.tl-left-main');
    var tree = this.getLefthandTree();
    var table = jQuery('<table class="tl-main-table"></table>');
    var body = jQuery('<tbody></tbody>');
    var head = jQuery('<thead></thead>');
    var row, cell, link, span, text;
    var timeline = this;
    var rows = this.getAvailableRows();
    var first = true; // for the first row
    var previousGroup = -1;
    var headerHeight = this.decoHeight();

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

      text = timeline.escape(data.subject || data.name);
      if (data.getUrl instanceof Function) {
        text = jQuery('<a href="' + data.getUrl() + '" class="tl-discreet-link" data-modal/>').append(text).attr("title", text);
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
        if (typeof rows[e] === "function") {
          cell.append(rows[e].call(data, data));
        } else {
          cell.append(rows.general.call(data, data, e));
        }
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

    var change = [];

    var maxWidth = jQuery("#content").width() * 0.25;
    table.find(".tl-word-ellipsis").each(function (i, e) {
      e = jQuery(e);

      var indent = e.offset().left - e.parent().offset().left;

      if (e.width() > maxWidth - indent) {
        change.push({e: e, w: maxWidth - indent});
      }
    });

    var i;
    for (i = 0; i < change.length; i += 1) {
      change[i].e.css("width", change[i].w);
    }
  },

  rebuildGraphBackbone: function(tree, ui_root){
    var timeline = this;
    var chart = ui_root;

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
      timeline.rebuildForegroundBackbone(tree);
    });
  },

  rebuildForegroundBackbone: function(tree) {
    var timeline = this;
    var previousGrouping = -1;
    var grouping;
    var width = timeline.getWidth();
    var previousNode;
    var render_buckets = [[], [], [], []];
    var render_bucket_vertical = render_buckets[0];
    var render_bucket_element = render_buckets[1];
    var render_bucket_vertical_milestone = render_buckets[2];
    var render_bucket_text = render_buckets[3];

    // iterate over all planning elements and find vertical ones to draw.
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
          render_bucket_vertical_milestone.push(function () {
            pl.renderVertical(node);
          });
        } else {
          render_bucket_vertical.push(function () {
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

            previousEnd = timeline.decoHeight();
          }

          // groupHeight is the height gap between the vertical position
          // at which the current element begins (currentOffset) and the
          // position the previous element ended (previousEnd).

          groupHeight = currentOffset - previousEnd;

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
        render_bucket_text.push(function () {
          pl.renderForeground(node);
        });
      }

      render_bucket_element.push(function() {
        pl.render(node);
      });
    }, {timeline: timeline});

    var buckets = Array.prototype.concat.apply([], render_buckets);

    var render_next_bucket = function() {
      if (buckets.length !== 0) {
        jQuery.each(buckets.splice(0, Timeline.RENDER_BUCKET_SIZE), function(i, e) {
          e.call();
        });
        timeline.defer(render_next_bucket);
      } else {
        timeline.finishGraph();
      }
    };

    render_next_bucket();
  },
});