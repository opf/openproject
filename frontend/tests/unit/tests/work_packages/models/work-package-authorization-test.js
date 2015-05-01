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

describe('WorkPackageAuthorization', function() {
  var WorkPackageAuthorization;
  var authorization;

  beforeEach(module('openproject.workPackages.models'));

  beforeEach(inject(function(_WorkPackageAuthorization_) {
    WorkPackageAuthorization = _WorkPackageAuthorization_;
  }));

  beforeEach(function() {
    var workPackage = {
      links: {
        delete: { href: 'deleteMeLink' },
        update: { href: 'updateMeLink' },
        log_time: { href: 'log_timeMeLink' },
      }
    };

    authorization = new WorkPackageAuthorization(workPackage);
  });

  describe('permittedActions', function() {
    describe('no allowed action passed', function() {
      it('returns empty set of permitted actions', function() {
        var permittedActions = authorization.permittedActions([]);

        expect(permittedActions).to.be.empty;
      });
    });

    describe('allowed action passed', function() {
      var allowedActions = ['delete', 'log_time'];
      var permittedActions;

      before(function() {
        permittedActions = authorization.permittedActions(allowedActions);
      });

      it('returns a non empty list', function() {
        expect(permittedActions).not.to.be.empty;
      });

      it('returns an object with permitted actions', function() {
        expect(Object.keys(permittedActions)).to.eql(allowedActions);
      });

      it('returns an object with links to permitted actions', function() {
        angular.forEach(permittedActions, function(value, key) {
          expect(value).to.eql(key + 'MeLink');
        });
      });
    });
  });
});
