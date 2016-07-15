export class WpDisplayFormattableFieldHelper {
  constructor(protected $scope,
              protected $element) {
      $element.on('click', 'a', function (evt) {
        evt.stopPropagation();
      });
  }
}

function wpDisplayFormattableFieldHelper():ng.IDirective {
  return {
    restrict: 'A',
    controller: WpDisplayFormattableFieldHelper
  };
}

angular.module('openproject.workPackages.directives').directive('wpDisplayFormattableFieldHelper', wpDisplayFormattableFieldHelper)
