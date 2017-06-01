//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

  var $httpBackend,
      $q,
      ActivityService,
      ConfigurationService,
      accessibilityModeEnabled;

  beforeEach(angular.mock.module('openproject.api', 'openproject.services', 'openproject.config',
    'openproject.models'));

  beforeEach(inject(function(_$q_, _$httpBackend_, _ActivityService_,  _ConfigurationService_) {
    $q = _$q_;
    $httpBackend   = _$httpBackend_;
    ActivityService = _ActivityService_;
    ConfigurationService = _ConfigurationService_;

    accessibilityModeEnabled = sinon.stub(ConfigurationService, 'accessibilityModeEnabled');
  }));

  describe('createComment', function() {
    var apiFetchResource;
    var activityId = 10;
    var comment = 'Jack Bauer 24 hour power shower';
    var activityUrl = '/api/v3/work_packages/10/activities';
    var workPackage = {
      id: 5,
      addComment: function() {
        return $q.when(true);
      }
    };

    beforeEach(inject(function($q) {
      accessibilityModeEnabled.returns(false);
      $httpBackend.when('POST', activityUrl)
        .respond({
          'project': {
            'id': activityId,
            'comment': comment,
          }
        });

      apiFetchResource = ActivityService.createComment(
        workPackage,
        comment
      );
    }));

    it('returns an activity', function() {
      apiFetchResource.then(function(activity){
        expect(activity.id).to.equal(activityId);
        expect(activity.comment).to.equal(comment);
      });
    });
  });
});
