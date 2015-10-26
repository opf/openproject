describe('Routing', function () {
  var $rootScope, $state, mockState = { go: function () {} };

  beforeEach(module('openproject', function ($provide) {
    $provide.value('$state', mockState);
  }));

  beforeEach(inject(function (_$rootScope_) {
    $rootScope = _$rootScope_;
  }));

  describe('when the project id is set', function () {
    var toState, toParams,
        spy = sinon.spy(mockState, 'go'),
        broadcast = function () {
          $rootScope.$broadcast('$stateChangeStart', toState, toParams);
        };

    beforeEach(function () {
      toState = { name: 'work-packages.list' };
      toParams = { projectPath: 'my_project', projects: null };
    });

    it('sets the projects path segment to "projects" ', function () {
      broadcast();
      expect(toParams.projects).to.equal('projects');
    });

    it('routes to the given state', function () {
      broadcast();
      expect(spy.withArgs(toState, toParams).called).to.be.true;
    });

    it('routes to child states of work-packages.list', function () {
      var childStates = ['child', 'my.other.child'];

      childStates.forEach(function (childState) {
        toState.name = 'work-packages.list.' + childState;
        broadcast();
        expect(spy.withArgs(toState, toParams).calledOnce).to.be.true;
      });
    });

    it('is ignored on other routes than work-packages.list', function () {
      toState.name = 'work-packages.other.route';
      broadcast();
      expect(spy.withArgs(toState, toParams).called).to.be.false;
    })
  });
});
