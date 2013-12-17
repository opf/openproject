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

/* Note to team:
  This file is very messy and basically contains methods that I wanted to change from
  ui.js whilst keeping the old ones so that I could refer to them. My goal would be to move
  anything here into the relevant backbone view class or back into ui.js which would then
  be as a library for the views.
*/

//UI?
jQuery.extend(Timeline, {

  completeUIBackbone: function(tree, ui_root) {
    var timeline = this;

    // construct tree on left-hand-side.
    // this.rebuildTreeBackbone(tree, ui_root);

    // lift the curtain, paper otherwise doesn't show w/ VML.
    jQuery('.timeline').removeClass('tl-under-construction');
    // if(this.paper === undefined){
    this.paper = new Raphael(ui_root.get()[0], 640, 480);
    // }

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

  zoomInBackbone: function() {
    this.zoomBackbone(this.zoomIndex + 1);
  },

  zoomOutBackbone: function() {
    this.zoomBackbone(this.zoomIndex - 1);
  },

  rebuildGraphBackground: function(tree, ui_root){
    var timeline = this;
    var chart = ui_root;

    // chart.css({'display': 'none'});

    var width = timeline.getWidth();
    var height = timeline.getHeight();

    // clear and resize
    timeline.paper.clear();
    timeline.paper.setSize(width, height);

    // Note RS: Not sure why that was being deferred but now it's not. let's see what breaks.
    timeline.rebuildBackground(tree, width, height);
    chart.css({'display': 'block'});
  },

  /*
     Assigns the project and planning element DOM elements to the appropriate tree nodes.
     This is the equivalent to the only part of the old buildTree method which is still useful.
  */
  setTreeDomElements: function(tree) {
    var options = {
      timeline: this,
      traverseCollapsed: true
    }

    tree.iterateWithChildren(function(node, indent) {
      var data = node.getData();

      if(data instanceof window.backbone_app.models.PlanningElement){
        var cell = jQuery("[data-cell-planning-element-id=" + data.get('id') + "]");
      } else {
        // Note: Only dealing with planning elements and projects just now
        var cell = jQuery("[data-cell-project-identifier=" + data.get('identifier') + "]");
      }
      node.setDOMElement(cell);

      // TODO RS: Massive amount of code removed here that probably does important stuff

    }, options);
  },

  adjustForPlanningElementsBackbone: function(project, planning_elements) {
    var timeline = this;
    var tree = this.getLefthandTreeBackbone(project, planning_elements);

    // nullify potential previous dates seen. this is relevant when
    // adjusting after the addition of a planning element via modal.

    timeline.firstDateSeen = null;
    timeline.lastDateSeen = null;

    tree.iterateWithChildren(function(node) {
      var data = node.getData();
      if (data instanceof window.backbone_app.models.PlanningElement) {
        timeline.includeDate(data.start());
        timeline.includeDate(data.end());
      }
    }, {
      traverseCollapsed: true,
      timeline: this,
    });

  },

  getLefthandTreeBackbone: function(project, planning_elements){
    var tree = Object.create(Timeline.TreeNode);
    var parent_stack = [];

    tree.setData(project);

    var count = 1;
    // for the given node, appends the given planning_elements as children,
    // recursively. every node will have the planning_element as data.
    var treeConstructor = function(node, elements) {
      count += 1;

      var MAXIMUMPROJECTCOUNT = 12000;
      if (count > MAXIMUMPROJECTCOUNT) {
        throw I18n.t('js.timelines.tooManyProjects', {count: MAXIMUMPROJECTCOUNT});
      }

      elements.each(function(e) {
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

    var lefthandTree = lefthandTree = treeConstructor(tree, planning_elements);
    lefthandTree.expandTo(0);
    return lefthandTree;
  },
});