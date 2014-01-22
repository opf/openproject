uiComponentsApp
  .filter('ancestorsExpanded', function() {
    return function(ancestors) {
      if(!ancestors) return true;

      return ancestors.map(function(ancestor){
        return ancestor.expanded;
      }).reduce(function(a,b){
        return a && b;
      });
    };
  });
