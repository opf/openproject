import {wpDirectivesModule} from '../../angular-modules';

export class MentionsAutoComplete {
  public availableWatchers;
  protected workPackage;
  protected textarea;

  constructor(protected $scope,
              protected $http,
              protected $element,
              protected UserMentions){
    var wpLoaded = $scope.$watch(function(){return $scope.workPackage},()=>{
      this.workPackage = $scope.workPackage;
      wpLoaded();
      this.init();
    });

  }
  
  protected init = () =>{
    // only link auto completion if user is allowed to add watchers
    if(this.workPackage.availableWatchers){

      this.UserMentions.loadAvailableWatchers(this.workPackage).then((availableWatchers)=>{
        (angular.element(this.$element) as any).atwho({
          at: '@',
          data: availableWatchers,
          displayTpl: "<li>${name} - <small>(${login})</small></li>",
          insertTpl: "@${name}(${id})"
        });
      });
    }
  };
}

function mentionsAutoCompleteDirective():ng.IDirective {
  return {
    require: ['^wpEditForm'],
    restrict: 'AC',
    controller: MentionsAutoComplete,
    link: function(scope,element,attrs,controllers){
      (scope as any).workPackage = controllers[0].workPackage;
    }
  };
}

wpDirectivesModule.directive('userMentionsAutocomplete', mentionsAutoCompleteDirective);
