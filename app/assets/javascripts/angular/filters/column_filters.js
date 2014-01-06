timelinesApp
  .filter('getOptionColumn', function() {
    var map = {
      "type": "getTypeName",
      "status": "getStatusName",
      "responsible": "getResponsibleName",
      "assigned_to": "getAssignedName",
      "project": "getProjectName"
    };

    return function(nodeData, option) {
      return nodeData[map[option]]();
    };
  });
