angular.module('openproject.workPackages.directives')

.directive('langAttribute', [function(){
  return {
    restrict: 'A',
    link: function(scope, element, attributes){
      if(scope.column && scope.column.custom_field){
        var langAttr = document.createAttribute('lang');
        langAttr.nodeValue = scope.column.custom_field.name_locale;
        element[0].setAttributeNode(langAttr);
      }
    }
  };
}]);