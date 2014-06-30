describe('queryMenuItem Directive', function() {
    var compile, element, rootScope, scope, html;
    var queryId = '25', stateParams = {};

    beforeEach(angular.mock.module('openproject.layout'));
    beforeEach(module('templates', 'openproject.services', 'openproject.models'));


    beforeEach(module('templates', function($provide) {
      $provide.value('$stateParams', stateParams);

      var QueryServiceMock = {
        queryName: 'Default',
        updateHighlightName: function() {
          return {
            then: function(callback) {
              return callback(QueryServiceMock.queryName[1]);
            }
          };
        }
      };
      $provide.value('QueryService', QueryServiceMock);
    }));

    beforeEach(inject(function($rootScope, $compile) {
      html = '<div query-menu-item object-id=' + queryId + '></div>';

      compile = function() {
        element = angular.element(html);
        rootScope = $rootScope;
        scope = $rootScope.$new();
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('when the query id does not match the state param', function() {
      beforeEach(function() {
        stateParams.query_id = '1';

        compile();
        rootScope.$broadcast('$stateChangeSuccess');
      });

      it('does not add the css-class "selected" to the element', function() {
        expect(element.hasClass('selected')).to.be.false;
      });
    });

    describe('when the query id matches the state param', function() {
      beforeEach(function() {
        stateParams.query_id = queryId;

        compile();
        rootScope.$broadcast('$stateChangeSuccess');
      });

      it('adds the css-class "selected" to the element', function() {
        expect(element.hasClass('selected')).to.be.true;
      });
    });

    describe('when the query id is undefined', function() {
      beforeEach(function() {
        html = '<div query-menu-item></div>';
      });

      describe('and the state param is null', function() {
        beforeEach(function() {
          stateParams.query_id = null;

          compile();
          rootScope.$broadcast('$stateChangeSuccess');
        });

        it('adds the css-class "selected" to the element', function() {
          expect(element.hasClass('selected')).to.be.true;
        });
      });

      describe('and the state param is set', function() {
        beforeEach(function() {
          stateParams.query_id = '25';

          compile();
          rootScope.$broadcast('$stateChangeSuccess');
        });

        it('does not add the css-class "selected" to the element', function() {
          expect(element.hasClass('selected')).to.be.false;
        });
      });
    });

    describe('when the renameQueryItem event is received', function() {
      var queryName = 'A query to find them all';

      beforeEach(function() {
        rootScope.$broadcast('openproject.layout.renameQueryMenuItem', {
          itemType: 'query-menu-item',
          queryid: queryId,
          queryName: queryName
        });
      });

      it('resets the menu item title', function() {
        expect(element.text()).to.equal(queryName);
      });
    });
});
