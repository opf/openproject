// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('iconWrapper', ['I18n', function(I18n){
  return {
    restrict: 'EA',
    replace: true,
    scope: { iconName: '@', title: '=iconTitle' },
    templateUrl: '/templates/components/icon_wrapper.html'
  };
}]);
