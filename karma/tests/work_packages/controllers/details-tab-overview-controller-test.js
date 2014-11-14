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
                                         'estimatedTime', 'versionName', 'spentTime'];

  var scope, ctrl;
  var buildController;
  var HookService;
  var WorkPackagesOverviewService;
  var I18n = { t: angular.identity },
      WorkPackagesHelper = {
        formatWorkPackageProperty: angular.identity
      },
      UserService = {
        getUser: angular.identity
      },
      VersionService = {
        getVersions: angular.identity
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
  var $q;

  function buildWorkPackageWithId(id) {
    angular.extend(workPackage.props, {id: id});
    return workPackage;
  }

  beforeEach(module('openproject.api',
                    'openproject.services',
                    'openproject.config',
                    'openproject.workPackages.controllers'));

  beforeEach(inject(function($rootScope, $controller, $timeout, _HookService_, _WorkPackagesOverviewService_, _$q_) {
    var workPackageId = 99;

    HookService = _HookService_;
    WorkPackagesOverviewService = _WorkPackagesOverviewService_;
    $q = _$q_;

    buildController = function() {
      scope = $rootScope.$new();
      scope.workPackage = workPackage;

      ctrl = $controller("DetailsTabOverviewController", {
        $scope:  scope,
        I18n: I18n,
        UserService: UserService,
        VersionService: VersionService,
        CustomFieldHelper: CustomFieldHelper,
        WorkPackagesOverviewService: WorkPackagesOverviewService,
        HookService: HookService
      });

      $timeout.flush();
    };
  }));

  describe('initialisation', function() {
    it('should initialise', function() {
      buildController();
    });
  });

  describe('work package properties', function() {
    function getProperties() {
      var properties = [];

      angular.forEach(scope.groupedAttributes, function(group) {
        angular.forEach(group.attributes, function(attribute) {
          properties.push(attribute);
        });
      });

      return properties;
    }

    function fetchPresentPropertiesWithName(propertyName) {
      return getProperties().filter(function(propertyData) {
        return propertyData.property === propertyName && propertyData.value != null;
      });
    }

    function fetchEmptyPropertiesWithName(propertyName) {
      return getProperties().filter(function(propertyData) {
        return propertyData.property === propertyName && propertyName.value == null;
      });
    }

    var shouldBehaveLikePropertyWithValue = function(propertyName) {
      it('adds property to present properties', function() {
        expect(fetchPresentPropertiesWithName(propertyName)).to.have.length(1);
      });
    };

    var shouldBehaveLikePropertyWithNoValue = function(propertyName) {
      it('adds property to present properties', function() {
        expect(fetchEmptyPropertiesWithName(propertyName)).to.have.length(1);
      });
    };

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
          workPackage.props.versionId = 1;
          workPackage.links = workPackage.links || {};
          buildController();
        });

        context('versionViewable is false or missing', function() {
          beforeEach(function() {
            buildController();
          });

          it ('should set the correct viewable property', function() {
            expect(fetchPresentPropertiesWithName('versionName')[0].value.viewable).to.equal(false);
          });
          it('should set the given title', function() {
            expect(fetchPresentPropertiesWithName('versionName')[0].value.title).to.equal('Test version');
          });
        });

        context('versionViewable is true', function() {
          beforeEach(function() {
          workPackage.links.version = {
            href: "/versions/1",
            props: {
              title: 'Test version'
            }
          };
            buildController();
          });

          it('should return the version as a link with correct href', function() {
            expect(fetchPresentPropertiesWithName('versionName')[0].value.href).to.equal('/versions/1');
          });

          it('should return the version as a link with correct title', function() {
            expect(fetchPresentPropertiesWithName('versionName')[0].value.title).to.equal('Test version');
          });

          it ('should set the correct viewable property', function() {
            expect(fetchPresentPropertiesWithName('versionName')[0].value.viewable).to.equal(true);
          });
        });

      });

      describe('is "user"', function() {
        beforeEach(function() {
          workPackage.embedded['assignee'] = { id: 1, name: 'Waya Namamo' };
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
          sinon.spy(CustomFieldHelper, 'formatCustomFieldValue');

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
          expect(fetchEmptyPropertiesWithName(customPropertyName)).not.to.be.empty;
        });
      });

      describe('user custom property', function() {
        var userId = '1';

        beforeEach(function() {
          workPackage.props.customProperties[0].value = userId;
          workPackage.props.customProperties[0].format = 'user';

          sinon.spy(UserService, 'getUser');
          buildController();
        });

        it('fetches the user using the user service', function() {
          expect(UserService.getUser.calledWith(userId)).to.be.true;
        });
      });

      describe('version custom property', function() {
        var versionId = '1';
        var versionName = 'A test version name';
        var customVersionName = 'My custom version';
        var errorMessage = 'my error message';
        var tStub;

        before(function() {
          workPackage.props.customProperties[0].name = customVersionName;
          workPackage.props.customProperties[0].value = versionId;
          workPackage.props.customProperties[0].format = 'version';

          tStub = sinon.stub(I18n, 't');
          tStub.withArgs('js.error_could_not_resolve_version_name').returns(errorMessage);
        });

        after(function() {
          tStub.restore();
        });

        var itBehavesLikeHavingAVersion = function(href, title, viewable) {
          var customVersion;

          before(function() {
            customVersion = fetchPresentPropertiesWithName(customVersionName)[0];
          });

          it('sets the custom version link title correctly', function() {
            expect(customVersion.value.title).to.equal(title);
          });

          it('sets the custom version link href correctly', function() {
            expect(customVersion.value.href).to.equal(href);
          });

          it('is viewable', function() {
            expect(customVersion.value.viewable).to.equal(viewable);
          });
        };

        describe('version available', function() {
          var getVersionsStub;

          before(function() {
            getVersionsStub = sinon.stub(VersionService, 'getVersions');

            getVersionsStub.returns([{ id: versionId, name: versionName }]);

            buildController();
          });

          after(function() {
            getVersionsStub.restore();
          });

          itBehavesLikeHavingAVersion('/versions/1', versionName, true);
        });

        describe('version not available', function() {
          before(function() {
            buildController();
          });

          itBehavesLikeHavingAVersion('/versions/1', errorMessage, true);
        });

        describe('list of versions not available', function() {
          var getVersionsStub;

          before(function() {
            var reject = $q.reject('For test reasons!');

            getVersionsStub = sinon.stub(VersionService, 'getVersions');

            getVersionsStub.returns(reject);

            buildController();
          });

          after(function() {
            getVersionsStub.restore();
          });

          itBehavesLikeHavingAVersion('/versions/1', errorMessage, true);
        });
      });
    });

    describe('Plug-in properties', function() {
      var propertyName = 'myPluginProperty';
      var directiveName = 'my-plugin-property-directive';

      before(function() {
        var workPackageOverviewAttributesStub = sinon.stub(HookService, "call");

        workPackageOverviewAttributesStub.withArgs('workPackageOverviewAttributes',
                                                   { type: propertyName,
                                                     workPackage: workPackage })
                                         .returns([directiveName]);
        workPackageOverviewAttributesStub.returns([]);

        WorkPackagesOverviewService.addAttributesToGroup('other', [propertyName]);

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
      var propertyNames = ['a', 'b', 'c'];

      beforeEach(function() {
        var stub = sinon.stub(I18n, 't');

        stub.withArgs('js.work_packages.properties.a').returns('z');
        stub.withArgs('js.work_packages.properties.b').returns('y');
        stub.withArgs('js.work_packages.properties.c').returns('x');
        stub.returnsArg(0);

        WorkPackagesOverviewService.addAttributesToGroup('other', propertyNames);

        buildController();
      });

      afterEach(function() {
        I18n.t.restore();
      });

      it('sorts list of non-empty properties', function() {
        var isSorted = function(element, index, array) {
          return index === 0 || String(array[index - 1].label.toLowerCase()) <= String(element.label.toLowerCase());
        };
        var groupOtherAttributes = WorkPackagesOverviewService.getGroupAttributesForGroupedAttributes('other', scope.groupedAttributes);
        expect(groupOtherAttributes.every(isSorted)).to.be.true;
      });
    });
  });
});
