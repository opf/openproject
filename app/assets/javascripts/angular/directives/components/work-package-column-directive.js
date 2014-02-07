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

      // Get display text from 'name' if it is an object
      var display_text = 'None';
      switch(typeof(data)) {
        case 'string':
          display_text = data;
          break;
        case 'object':
          display_text = data['name'];
          break;
      }

      // Set type specific scope
      scope.display_type = scope.column.display_type;
      switch (scope.column.display_type){
        case 'text':
          // Nothing special
          scope.model = display_text;
          break;
        case 'work_package_link':
          scope.url = '/work_packages/' + scope.model.object['id'];
          scope.model = display_text;
          break;
      }

    }
  };
}]);
