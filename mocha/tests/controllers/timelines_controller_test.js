/*jshint expr: true*/

var gon = { timeline_options: { } };

describe('TimelinesController', function() {

  beforeEach(module('openproject.timelines.controllers'));

  it('should exist', function() {

    inject(function($rootScope, $controller) {
      var scope = $rootScope.$new();

      ctrl = $controller("TimelinesController", {
        $scope: scope,
        Timeline: {}
      });

      //expect(scope.timelineOptions).to.equal({});
      expect(scope.timelineContainerCount).to.equal(0);
    });

  });

});
