describe('inaccessibleByTab Directive', function() {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.uiComponents'));
  beforeEach(module('templates'));

  beforeEach(inject(function($rootScope, $compile) {
    var html =
      '<a inaccessible-by-tab="boolValue"></a>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('tabindex', function() {
    it('should be -1 for true', function() {
      scope.boolValue = true;
      compile();
      expect(element.attr('tabindex')).to.eq("-1");
    });

    it('should not be -1 for false', function() {
      scope.boolValue = false;
      compile();
      expect(element.attr('tabindex')).to.be.undefined;
    });
    
    it('should change if the directive attr changes', function() {
      scope.boolValue = false;
      compile();
      expect(element.attr('tabindex')).to.be.undefined;
      scope.boolValue = true;
      scope.$digest();
      expect(element.attr('tabindex')).to.eq("-1");
    });
  });
});