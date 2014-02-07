// TODO move to UI components

openprojectApp.directive('workPackageColumn', [function(){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      model: '=',
      column: '='
    },
    templateUrl: '/templates/components/work_package_column.html',
    link: function(scope, element, attributes) {
      var data = scope.model.object[scope.column.name];
      var defaultText = '';

      // Get display text from 'name' if it is an object
      var displayText = defaultText;
      switch(typeof(data)) {
        case 'string':
          displayText = data;
          break;
        case 'object':
          displayText = data['name'];
          break;
      }

      // Set type specific scope
      scope.display_type = scope.column.display_type;
      switch (scope.column.display_type){
        case 'text':
          // Nothing special
          scope.displayText = displayText;
          break;
        case 'work_package_link':
          scope.url = '/work_packages/' + scope.model.object['id'];
          scope.displayText = displayText;
          break;
      }

    }
  };
}]);
