// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('iconWrapper', [function(){
  return {
    restrict: 'EA',
    replace: true,
    scope: { iconName: '@', title: '@iconTitle' },
    templateUrl: '/templates/components/icon_wrapper.html'
  };
}]);
