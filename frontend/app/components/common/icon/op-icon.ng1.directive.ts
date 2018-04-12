import {opUiComponentsModule} from 'core-app/angular-modules';

function opIcon() {
  return {
    restrict: 'EA',
    scope: {
      iconClasses: '@',
      iconTitle: '@'
    },
    link: (_scope:ng.IScope, element:ng.IAugmentedJQuery) => {
      element.addClass('op-icon--wrapper');
    },
    template: `
      <i class="{{iconClasses}}" aria-hidden="true"></i>
      <span class="hidden-for-sighted" ng-bind="iconTitle" ng-if="iconTitle"></span>
    `
  };
}

opUiComponentsModule.directive('opIcon', opIcon);
