timelinesApp
  .filter('historicalDateKind', function() {
    return function(nodeData, dateOption) {
      var newDate = nodeData[dateOption];
      var oldDate = nodeData.historical()[dateOption];

      if (oldDate && newDate) {
        return (newDate < oldDate ? 'postponed' : 'preponed');
      }
      return "changed";
    };
  })

  .filter('getOptionColumn', function() {
    var map = {
      "type": "getTypeName",
      "status": "getStatusName",
      "responsible": "getResponsibleName",
      "assigned_to": "getAssignedName",
      "project": "getProjectName"
    };

    return function(nodeData, option) {
      switch(option) {
        case 'start_date':
          return nodeData.start_date;
        case 'due_date':
          return nodeData.due_date;
        default:
          return nodeData[map[option]]();
      }
    };
  });
