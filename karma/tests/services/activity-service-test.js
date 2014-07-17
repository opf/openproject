//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

describe('ActivityService', function() {

  var $httpBackend, ActivityService;
  beforeEach(module('openproject.api', 'openproject.services', 'openproject.models'));

  beforeEach(inject(function(_$httpBackend_, _ActivityService_) {
    $httpBackend   = _$httpBackend_;
    ActivityService = _ActivityService_;
  }));

  describe('createComment', function() {
    var setupFunction;
    var workPackageId = 5;
    var actvityId = 10;
    var activities = [];
    var descending = false;
    var comment = "Jack Bauer 24 hour power shower";
    var apiResource;
    var apiFetchResource;

    beforeEach(inject(function($q) {
      apiResource = {
        fetch: function() {
          deferred = $q.defer();
          deferred.resolve({ id: actvityId, comment: comment } );
          return deferred.promise;
        }
      }
    }));

    beforeEach(inject(function(HALAPIResource) {
      setupFunction = sinon.stub(HALAPIResource, 'setup').returns(apiResource);
    }));

    beforeEach(inject(function() {
      apiFetchResource = ActivityService.createComment(workPackageId, activities, descending, comment);
    }));

    it('makes an api setup call', function() {
      expect(setupFunction).to.have.been.calledWith("work_packages/" + workPackageId + "/activities");
    });

    it('returns an activity', function() {
      apiFetchResource.then(function(activity){
        expect(activity.id).to.equal(activityId);
        expect(activity.comment).to.equal(comment);
        expect(activities.length).to.equal(1);
      });
    });

  });
});
