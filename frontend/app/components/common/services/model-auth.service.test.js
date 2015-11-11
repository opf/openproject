// -- copyright
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
// ++

/*jshint expr: true*/

describe('AuthorisationService', function() {

  var AuthorisationService, $rootScope, query;

  beforeEach(angular.mock.module('openproject.services', 'openproject.models'));

  beforeEach(inject(function(_AuthorisationService_, _$rootScope_){
    AuthorisationService = _AuthorisationService_;
    $rootScope = _$rootScope_;
  }));

  describe('model action authorisation', function () {
    beforeEach(function(){
      AuthorisationService.initModelAuth('query', {
        create: '/queries'
      });
    });

    it('should allow action', function() {
      expect(AuthorisationService.can('query', 'create')).to.be.true;
      expect(AuthorisationService.cannot('query', 'create')).to.be.false;
    });

    it('should not allow action', function() {
      expect(AuthorisationService.can('query', 'delete')).to.be.false;
      expect(AuthorisationService.cannot('query', 'delete')).to.be.true;
    });

    it('should call an event on initialisation', function () {
      var eventCalled = false;

      $rootScope.$on('modelAuthUpdate.my_model', function () {
        eventCalled = true;
      });

      AuthorisationService.initModelAuth('my_model');
      expect(eventCalled).to.be.true;
    });
  });
});
