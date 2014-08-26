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

describe('DetailsTabOverviewController', function() {
  var DEFAULT_WORK_PACKAGE_PROPERTIES = ['status', 'assignee', 'responsible',
                                         'date', 'percentageDone', 'priority',
                                         'estimatedTime', 'versionName', 'spentTime']

  var scope;
  var buildController;
  var HookService;
  var ConfigurationService;
  var I18n = { t: angular.identity },
      WorkPackagesHelper = {
        formatWorkPackageProperty: angular.identity
      },
      UserService = {
        getUser: angular.identity
      },
      CustomFieldHelper = {
        formatCustomFieldValue: angular.identity
      },
      workPackage = {
        props: {
          status: 'open',
          versionName: null,
          percentageDone: 0,
          estimatedTime: undefined,
          spentTime: 'A lot!',
          customProperties: [
            { format: 'text', name: 'color', value: 'red' },
            { format: 'text', name: 'Width', value: '' },
            { format: 'text', name: 'height', value: '' },
          ]
        },
        embedded: {
          activities: [],
          watchers: [],
          attachments: []
        },
      };
  var workPackageAttributesStub;

  function buildWorkPackageWithId(id) {
    angular.extend(workPackage.props, {id: id});
    return workPackage;
  }

  beforeEach(module('openproject.api',
                    'openproject.services',
                    'openproject.config',
                    'openproject.workPackages.controllers'));

  beforeEach(inject(function($rootScope, $controller, $timeout, _HookService_, _ConfigurationService_) {
    var workPackageId = 99;

    buildController = function() {
      scope = $rootScope.$new();
      scope.workPackage = workPackage;

      ctrl = $controller("DetailsTabOverviewController", {
        $scope:  scope,
        I18n: I18n,
        UserService: UserService,
        CustomFieldHelper: CustomFieldHelper,
      });

      $timeout.flush();
    };

    HookService = _HookService_;
    ConfigurationService = _ConfigurationService_;

    workPackageAttributesStub = sinon.stub(ConfigurationService, "workPackageAttributes");
    workPackageAttributesStub.returns(DEFAULT_WORK_PACKAGE_PROPERTIES);
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

    function fetchEmptyPropertiesWithName(propertyName) {
      return scope.emptyWorkPackageProperties.filter(function(propertyData) {
        return propertyData.property === propertyName;
      });
    }

    var shouldBehaveLikePropertyWithValue = function(propertyName) {
      it('adds property to present properties', function() {
        expect(fetchPresentPropertiesWithName(propertyName)).to.have.length(1);
      });
    }

    var shouldBehaveLikePropertyWithNoValue = function(propertyName) {
      it('adds property to present properties', function() {
        expect(fetchEmptyPropertiesWithName(propertyName)).to.have.length(1);
      });
    }

    describe('when the property has a value', function() {
      beforeEach(function() {
        buildController();
      });

      describe('status', function() {
        var propertyName = 'status';

        shouldBehaveLikePropertyWithValue(propertyName);
      });

      describe('percentage done', function() {
        var propertyName = 'percentageDone';

        shouldBehaveLikePropertyWithValue(propertyName);
      });
    });

    describe('when the property has NO value', function() {
      beforeEach(function() {
        buildController();
      });

      describe('estimated Time', function() {
        var propertyName = 'estimatedTime';

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

    describe('date property', function() {
      var startDate = '2014-07-09',
          dueDate   = '2014-07-10',
          placeholder = 'placeholder';


      describe('when only the due date is present', function() {
        beforeEach(function() {
          sinon.stub(I18n, 't')
               .withArgs('js.label_no_start_date')
               .returns(placeholder);

          workPackage.props.startDate = null;
          workPackage.props.dueDate = dueDate;

          buildController();
        });

        afterEach(function() {
          I18n.t.restore();
        });

        it('renders the due date and a placeholder for the start date as date property', function() {
          expect(fetchPresentPropertiesWithName('date')[0].value).to.equal(placeholder + ' - 07/10/2014');
        });
      });

      describe('when only the start date is present', function() {
        beforeEach(function() {
          sinon.stub(I18n, 't')
               .withArgs('js.label_no_due_date')
               .returns(placeholder);

          workPackage.props.startDate = startDate;
          workPackage.props.dueDate = null;

          buildController();
        });

        afterEach(function() {
          I18n.t.restore();
        });

        it('renders the start date and a placeholder for the due date as date property', function() {
          expect(fetchPresentPropertiesWithName('date')[0].value).to.equal('07/09/2014 - ' + placeholder);
        });
      });

      describe('when both - start and due date are present', function() {
        beforeEach(function() {
          workPackage.props.startDate = startDate;
          workPackage.props.dueDate = dueDate;

          buildController();
        });

        it('combines them and renders them as date property', function() {
          expect(fetchPresentPropertiesWithName('date')[0].value).to.equal('07/09/2014 - 07/10/2014');
        });
      });
    });

    describe('property format', function() {
      describe('is "version"', function() {
        beforeEach(function() {
          workPackage.props.versionName = 'Test version';
          workPackage.props.versionId = 1
          buildController();
        });

        it('should return the version as a link with correct href', function() {
          expect(fetchPresentPropertiesWithName('versionName')[0].value.href).to.equal('/versions/1');
        });

        it('should return the version as a link with correct title', function() {
          expect(fetchPresentPropertiesWithName('versionName')[0].value.title).to.equal('Test version');
        });
      });

      describe('is "user"', function() {
        beforeEach(function() {
          workPackage.embedded['assignee'] = { id: 1, name: 'Waya Namamo' }
          buildController();
        });

        it('should return object with correct id', function() {
          expect(fetchPresentPropertiesWithName('assignee')[0].value.id).to.equal(1);
        });

        it('should return object with correct name', function() {
          expect(fetchPresentPropertiesWithName('assignee')[0].value.name).to.equal('Waya Namamo');
        });
      });
    });

    describe('custom field properties', function() {
      var customPropertyName = 'color';

      describe('when the property has a value', function() {
        beforeEach(function() {
          formatCustomFieldValueSpy = sinon.spy(CustomFieldHelper, 'formatCustomFieldValue');

          buildController();
        });

        afterEach(function() {
          CustomFieldHelper.formatCustomFieldValue.restore();
        });

        it('adds properties to present properties', function() {
          expect(fetchPresentPropertiesWithName(customPropertyName)).to.have.length(1);
        });

        it('formats values using the custom field helper', function() {
          expect(CustomFieldHelper.formatCustomFieldValue.calledWith('red', 'text')).to.be.true;
        });
      });

      describe('when the property does not have a value', function() {
        beforeEach(function() {
          workPackage.props.customProperties[0].value = null;
          buildController();
        });

        it('adds the custom property to empty properties', function() {
          expect(scope.emptyWorkPackageProperties.indexOf(customPropertyName)).to.be.greaterThan(-1);
        });
      });

      describe('user custom property', function() {
        var userId = '1';

        beforeEach(function() {
          workPackage.props.customProperties[0].value = userId;
          workPackage.props.customProperties[0].format = 'user';

          getUserSpy = sinon.spy(UserService, 'getUser');
          buildController();
        });

        it('fetches the user using the user service', function() {
          expect(UserService.getUser.calledWith(userId)).to.be.true;
        });
      });
    });

    describe('Plug-in properties', function() {
      var propertyName = 'myPluginProperty';
      var directiveName = 'my-plugin-property-directive';

      beforeEach(function() {
        gon.settings = { };
        gon.settings.work_package_attributes = [propertyName];

        var attributes = DEFAULT_WORK_PACKAGE_PROPERTIES.slice(0);
        attributes.push(propertyName);

        workPackageAttributesStub.returns(attributes);

        var workPackageOverviewAttributesStub = sinon.stub(HookService, "call");
        workPackageOverviewAttributesStub.withArgs('workPackageOverviewAttributes',
                                                   { type: propertyName,
                                                     workPackage: workPackage })
                                         .returns([directiveName]);
        workPackageOverviewAttributesStub.returns([]);

        buildController();
      });

      it('adds plug-in property to present properties', function() {
        expect(fetchPresentPropertiesWithName(propertyName)).to.have.length(1);
      });

      it('adds plug-in property to present properties', function() {
        var propertyData = fetchPresentPropertiesWithName(propertyName)[0];

        expect(propertyData.property).to.eq(propertyName);
        expect(propertyData.format).to.eq('dynamic');
        expect(propertyData.value).to.eq(directiveName);
      });
    });

    describe('Properties are sorted', function() {
      beforeEach(function() {
        var stub = sinon.stub(I18n, 't');

        stub.withArgs('js.work_packages.properties.spentTime').returns('SpentTime');
        stub.returnsArg(0);

        buildController();
      });

      afterEach(function() {
        I18n.t.restore();
      });

      it('sorts list of non-empty properties', function() {
        var isSorted = function(element, index, array) {
          return index === 0 || String(array[index - 1].label.toLowerCase()) <= String(element.label.toLowerCase());
        };
        // Don't consider the first 6 properties because those are predefined
        // and will not be sorted.
        expect(scope.presentWorkPackageProperties.slice(6).every(isSorted)).to.be.true;
      });

      it('sorts list of empty properties', function() {
        var isSorted = function(element, index, array) {
          return index === 0 || String(array[index - 1].toLowerCase()) <= String(element.toLowerCase());
        };
        expect(scope.emptyWorkPackageProperties.every(isSorted)).to.be.true;
      });
    });
  });
});
