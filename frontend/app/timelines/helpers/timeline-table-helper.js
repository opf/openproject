//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

module.exports = function() {
  var NodeFilter = function(options) {
    this.options = options;
  };

  NodeFilter.prototype.memberOfHiddenOtherGroup = function(node) {
    return this.options && this.options.hide_other_group === 'yes' && node.level === 1 && node.payload.objectType === 'Project' && node.payload.getFirstLevelGrouping() === 0;
  };

  NodeFilter.prototype.hiddenOrFilteredOut = function(node) {
    var nodeObject = node.payload;

    return nodeObject.hide() || nodeObject.filteredOut();
  };

  NodeFilter.prototype.nodeExcluded = function(node) {
    return this.hiddenOrFilteredOut(node) || this.memberOfHiddenOtherGroup(node);
  };

  var TimelineTableHelper = {
    flattenTimelineTree: function(root, filterCallback, processNodeCallback){
      var nodes = [];

      angular.forEach(root.childNodes, function(node){
        if (!filterCallback(node)) {
          // add relevant information to row
          if (processNodeCallback) processNodeCallback(node, root);

          // add subtree to nodes
          nodes.push(node);
          nodes = nodes.concat(TimelineTableHelper.flattenTimelineTree(node, filterCallback, processNodeCallback));
        }
      });

      return nodes;
    },

    addRowDataToNode: function(node, parent) {
      // ancestors
      if (parent) {
        node.ancestors = [parent];
        if(parent.ancestors) node.ancestors = parent.ancestors.concat(node.ancestors);

      }

      // first level group
      var isNested = node.level >= 2;
      if (node.payload.objectType === 'Project' && !isNested) {
        node.firstLevelGroup        = node.payload.getFirstLevelGrouping();
        node.firstLevelGroupingName = node.payload.getFirstLevelGroupingName();
      } else {
        // inherit group from parent
        node.firstLevelGroup = parent.firstLevelGroup;
      }
    },

    getTableRowsFromTimelineTree: function(tree, options) {
      var nodeFilter = new NodeFilter(options);

      // add relevant information to tree root serving as first row
      TimelineTableHelper.addRowDataToNode(tree);

      var rows = TimelineTableHelper.flattenTimelineTree(tree, function(node) { return nodeFilter.nodeExcluded(node); }, TimelineTableHelper.addRowDataToNode);
      rows.unshift(tree);

      return rows;
    },

    setLastVisible: function(rows) {
      var set = false;
      var i = rows.length - 1;
      while(i >= 0){
        if(!set && rows[i].visible){
          rows[i].setLastVisible();
          set = true;
        } else {
          rows[i].resetLastVisible();
        }
        i--;
      }
    },

    setRowLevelVisibility: function(rows, level) {
      angular.forEach(rows, function(row) {
        if(row.level <= level) {
          row.setVisible();
        } else {
          row.resetVisible();
        }
      });
      TimelineTableHelper.setLastVisible(rows);
    },

    applyToNodes: function(nodes, method, recurse){
      var method = method;
      angular.forEach(nodes, function(node){
        method(node);
        if(node.childNodes && recurse){
          TimelineTableHelper.applyToNodes(node.childNodes, method, recurse);
        }
      });
    }
  };

  return TimelineTableHelper;
};
