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

describe('CategoryService', function() {

  var CategoryService, $httpBackend;
  var projectIdentifier = 'ocarina',
      apiPath = '/api/v3/projects/' + projectIdentifier + '/categories';

  beforeEach(module('openproject.services'));

  beforeEach(inject(function(_$httpBackend_, _CategoryService_){
    $httpBackend   = _$httpBackend_;
    CategoryService = _CategoryService_;
  }));

  afterEach(function() {
    $httpBackend.verifyNoOutstandingExpectation();
    $httpBackend.verifyNoOutstandingRequest();
  });

  describe('getCategories', function() {

    var categories = [
      { id: 1, name: 'Happy Mask' },
      { id: 2, name: 'A Salesman' }
    ];

    beforeEach(function() {
      $httpBackend.when('GET', apiPath)
        .respond({ _embedded: { elements: categories } });
    });

    it('loads the categories sorted by their name', function() {
      $httpBackend.expectGET(apiPath);

      var callback = sinon.spy();
      CategoryService.getCategories(projectIdentifier).then(callback);

      $httpBackend.flush();
      expect(callback).to.have.been.calledWith(sinon.match([
        { id: 2, name: 'A Salesman' },
        { id: 1, name: 'Happy Mask' }
      ]));
    });

  });
});
