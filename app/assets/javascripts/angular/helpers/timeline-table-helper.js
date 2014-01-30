openprojectApp.factory('TimelineTableHelper', [function() {
  var NodeFilter = function(options) {
    this.options = options;
  };

  NodeFilter.prototype.excludeNode = function(node) {
    return this.options && this.options.hide_other_group === 'yes' && node.level === 1 && node.payload.objectType === 'Project' && node.payload.getFirstLevelGrouping() === 0;
  };

  TimelineTableHelper = {
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
      isNested = node.level >= 2;
      if (node.payload.objectType === 'Project' && !isNested) {
        node.firstLevelGroup        = node.payload.getFirstLevelGrouping();
        node.firstLevelGroupingName = node.payload.getFirstLevelGroupingName();
      } else {
        // inherit group from parent
        node.firstLevelGroup = parent.firstLevelGroup;
      }
    },

    getTableRowsFromTimelineTree: function(tree, options) {
      nodeFilter = new NodeFilter(options);

      // add relevant information to tree root serving as first row
      TimelineTableHelper.addRowDataToNode(tree);

      rows = TimelineTableHelper.flattenTimelineTree(tree, function(node) { return nodeFilter.excludeNode(node); }, TimelineTableHelper.addRowDataToNode);
      rows.unshift(tree);

      return rows;
    }
  };

  return TimelineTableHelper;
}]);
