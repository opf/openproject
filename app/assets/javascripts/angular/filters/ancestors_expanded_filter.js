openprojectApp
  .filter('ancestorsExpanded', function() {
    return function(ancestors) {
      if(!ancestors) return true;

      var directAncestors;

      if(ancestors.length > 1 && ancestors[0].payload.objectType === 'Project' && ancestors[1].payload.objectType === 'Project') {
        // discard expansion state of root if there's another project ancestor
        directAncestors = ancestors.slice(1);
      } else {
        directAncestors = ancestors;
      }

      return directAncestors.map(function(ancestor){
        return ancestor.expanded;
      }).reduce(function(a,b){
        return a && b;
      });
    };
  });
