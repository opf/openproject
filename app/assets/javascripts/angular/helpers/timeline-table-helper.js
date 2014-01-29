openprojectApp.factory('TimelineTableHelper', [function() {
  TimelineTableHelper = {
    flattenTimelineTree: function(root, processNodeCallback){
      nodes = [];

      angular.forEach(root.childNodes, function(node){
        if (processNodeCallback) processNodeCallback(node, root);

        nodes.push(node);
        nodes = nodes.concat(TimelineTableHelper.flattenTimelineTree(node, processNodeCallback));
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
      if(node.payload.objectType === 'Project') {
        node.firstLevelGroup        = node.payload.getFirstLevelGrouping();
        node.firstLevelGroupingName = node.payload.getFirstLevelGroupingName();
      }
    },

    getTableRowsFromTimelineTree: function(tree) {
      rows = TimelineTableHelper.flattenTimelineTree(tree, TimelineTableHelper.addRowDataToNode);

      TimelineTableHelper.addRowDataToNode(tree);
      rows.unshift(tree);

      return rows;
    }
  };

  return TimelineTableHelper;
}]);
