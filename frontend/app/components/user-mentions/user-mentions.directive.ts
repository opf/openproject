import {wpDirectivesModule} from '../../angular-modules';

export class mentions {
  public availableWatchers;
  protected workPackage;

  constructor(protected $scope,
              protected $http,
              protected $element,
              protected PathHelper,
              protected UserMentions){
    var wpLoaded = $scope.$watch(function(){return $scope.workPackage},()=>{
      this.workPackage = $scope.workPackage;
      wpLoaded();
      UserMentions.loadAvailableWatchers(this.workPackage).then(()=>{
        this.init();
      })
    });

  }

  protected init = () =>{
    
  };
}

function mentionsDirective():ng.IDirective {
  return {
    require: ['^wpEditForm'],
    restrict: 'AC',
    controller: mentions,
    link: function(scope,element,attrs,controllers){
      (scope as any).workPackage = controllers[0].workPackage;
    }
  };
}

wpDirectivesModule.directive('userMentions', mentionsDirective);
