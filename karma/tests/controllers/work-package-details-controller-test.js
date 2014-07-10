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

describe('WorkPackageDetailsController', function() {
  var scope;
  var buildController;
  var I18n = { t: angular.noop },
      workPackage = {
        props: {
          status: 'open',
          versionName: null
        },
        embedded: {
          activities: []
        },
      };

  function buildWorkPackageWithId(id) {
    angular.extend(workPackage.props, {id: id});
    return workPackage;
  }

  beforeEach(module('openproject.api', 'openproject.services', 'openproject.workPackages.controllers'));
  beforeEach(inject(function($rootScope, $controller, $timeout) {

    var workPackageId = 99;

    buildController = function() {
      scope = $rootScope.$new();

      ctrl = $controller("WorkPackageDetailsController", {
        $scope:  scope,
        $stateParams: { workPackageId: workPackageId },
        I18n: I18n,
        ConfigurationService: {
          commentsSortedInDescendingOrder: function() {
            return false;
          }
        },
        workPackage: buildWorkPackageWithId(workPackageId),
      });

      // $timeout.flush();
    };

  }));

  describe('initialisation', function() {
    it('should initialise', function() {
      buildController();
    });
  });

  describe('work package properties', function() {
    function fetchPresentPropertiesWithName(propertyName) {
      return scope.presentWorkPackageProperties.filter(function(propertyData) {
        return propertyData.property === propertyName;
      });
    }



    describe('when the property has a value', function() {
      var propertyName = 'status';

      beforeEach(function() {
        buildController();
      });

      it('adds properties to present properties', function() {
        expect(fetchPresentPropertiesWithName(propertyName)).to.have.length(1);
      });
    });

    describe('when the property is among the first 3 properties', function() {
      var propertyName = 'responsible';

      beforeEach(function() {
        buildController();
      });

      it('is added to present properties even if it is empty', function() {
        expect(fetchPresentPropertiesWithName(propertyName)).to.have.length(1);
      });
    });

    describe('when the property is among the second group of 3 properties', function() {
      var propertyName = 'priority',
          label        = 'Priority';

      beforeEach(function() {
        sinon.stub(I18n, 't')
             .withArgs('js.work_packages.properties.' + propertyName)
             .returns(label);

        buildController();
      });

      afterEach(function() {
        I18n.t.restore();
      });

      describe('and none of these 3 properties is present', function() {
        beforeEach(function() {
          buildController();
        });

        it('is added to the empty properties', function() {
          expect(scope.emptyWorkPackageProperties.indexOf(label)).to.be.greaterThan(-1);
        });
      });

      describe('and at least one of these 3 properties is present', function() {
        beforeEach(function() {
          workPackage.props.percentageDone = '20';
          buildController();
        });

        it('is added to the present properties', function() {
          expect(fetchPresentPropertiesWithName(propertyName)).to.have.length(1);
        });
      });
    });

    describe('when the property is not among the first 6 properties', function() {
      var propertyName = 'versionName',
          label        = 'Version';

      beforeEach(function() {
        sinon.stub(I18n, 't')
             .withArgs('js.work_packages.properties.' + propertyName)
             .returns(label);

        buildController();
      });

      afterEach(function() {
        I18n.t.restore();
      });

      it('adds properties that without values to empty properties', function() {
        expect(scope.emptyWorkPackageProperties.indexOf(label)).to.be.greaterThan(-1);
      });
    });
  });

});
