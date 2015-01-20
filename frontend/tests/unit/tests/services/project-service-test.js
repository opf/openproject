//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe('ProjectService', function() {

  var $httpBackend, ProjectService;
  beforeEach(module('openproject.services', 'openproject.models'));

  beforeEach(inject(function(_$httpBackend_, _ProjectService_) {
    $httpBackend   = _$httpBackend_;
    ProjectService = _ProjectService_;
  }));

  afterEach(function() {
    $httpBackend.verifyNoOutstandingExpectation();
    $httpBackend.verifyNoOutstandingRequest();
  });

  describe('getProject', function() {
    beforeEach(function() {
      $httpBackend.when('GET', '/api/experimental/projects/superProject')
        .respond({
          "project": {
            "id": 99,
            "name": "Super-Duper Project",
            "parent_id": null,
            "leaf?": true
          }
        });
    });

    it('sends a successful get request', function() {
      $httpBackend.expectGET('/api/experimental/projects/superProject');

      var callback = sinon.spy(),
        project    = ProjectService.getProject('superProject').then(callback);

      $httpBackend.flush();
      expect(callback).to.have.been.calledWith(sinon.match({
        name: "Super-Duper Project"
      }));
    });

    it('sends a unsuccessful get request', function() {
      $httpBackend.expectGET('/api/experimental/projects/superProject').respond(401);

      var success = sinon.spy(),
        error    = sinon.spy(),
        project  = ProjectService.getProject('superProject').then(success, error);

      $httpBackend.flush();
      expect(success).not.to.have.been.called;
      expect(error).to.have.been.called;
    });
  });
});
