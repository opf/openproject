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

module.exports = function() {

  TreeNode = {
    payload: undefined,
    parentNode: undefined,
    childNodes: undefined,
    expanded: false,
    lastExpanded: false,
    visible: false,

    totalCount: 0,
    projectCount: 0,

    getData: function() {
      return this.payload;
    },
    setData: function(data, level) {
      this.text = data.subject || data.name;
      if (data.is(Project)) this.group = data.getFirstLevelGrouping();
      this.url = data.getUrl();

      this.payload = data;
      this.level = level;

      return this;
    },
    appendChild: function(node) {
      if (!this.childNodes) {
        this.childNodes = [node];
      } else {
        this.childNodes.push(node);
      }
      node.parentNode = this;
      return node.parentNode;
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
      this.expanded = state;
      return this.expanded;
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
    setVisible: function(){
      this.visible = true;
    },
    resetVisible: function(){
      this.visible = false;
    },
    setLastVisible: function(){
      this.lastVisible = true;
    },
    resetLastVisible: function(){
      this.lastVisible = false;
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
          this.payload.is(Project) &&
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

          if (this.payload.is(Project)) {
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
                child.payload.is(Project)) {

                //do we wan to inherit the hidden status from projects to planning elements?
                if (!hidden || child.payload.is(Project)) {
                  if (!(options.indent > 1 && child.payload.is(Project))) {
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
  };

  return TreeNode;
};
