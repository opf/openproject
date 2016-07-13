import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {UserResource} from '../../api/api-v3/hal-resources/user-resource.service';

export class MentionsAutoComplete {
  protected workPackage: WorkPackageResourceInterface;

  constructor(protected $scope,
              protected $timeout,
              protected $element,
              protected UserMentions,
              protected wpWatchers) {
    var wpLoaded = $scope.$watch(function(){ return $scope.workPackage; }, (wp) => {
      if (angular.isDefined(wp)) {
        this.workPackage = $scope.workPackage;
        UserMentions.loadAvailableWatchers(this.workPackage).then(() => {
          wpLoaded();
          this.init();
        });
      }
    });
  }

  protected init():void {
    var availableWatchers: Array<any> = this.generateUsersArray();

    (angular.element(this.$element) as any).atwho({
      at: '@',
      data: availableWatchers,
      displayTpl: '<li>${name}</li>',
      insertTpl: '@${name}(${id})'
    });
  }

  protected generateUsersArray():Array<any> {
    var users:Array<any> = [];
    this.UserMentions.availableWatchers.forEach((watcher:UserResource) => {
      users.push({name: watcher.firstName + ' ' + watcher.lastName, id: watcher.id});
    });
    return users;
  }
}

function mentionsAutoCompleteDirective():ng.IDirective {
  return {
    require: ['^wpEditForm'],
    restrict: 'AC',
    controller: MentionsAutoComplete,
    link: function(scope, element, attrs, controllers){
      (scope as any).workPackage = controllers[0].workPackage;
    }
  };
}

wpDirectivesModule.directive('userMentionsAutocomplete', mentionsAutoCompleteDirective);
