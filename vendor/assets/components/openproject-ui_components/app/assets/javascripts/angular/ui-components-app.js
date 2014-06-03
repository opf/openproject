var uiComponentsApp = angular.module('openproject.uiComponents', ['ui.select2'])
  .run(['$rootScope', function($rootScope){
    $rootScope.I18n = I18n;
  }]);
