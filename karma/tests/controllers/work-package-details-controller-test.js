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
          customProperties: [
            { format: 'text', name: 'color', value: 'red' },
          ]
        },
        embedded: {
          activities: [],
          watchers: [],
          attachments: [],
          relations: [
            {
              props: {
                _type: "Relation::Relates"
              },
              links: {
                relatedFrom: {
                  fetch: sinon.spy()
                },
                relatedTo: {
                  fetch: sinon.spy()
                }
              }
            }
          ]
        },
        links: {
          self: "it's a me, it's... you know...",
          availableWatchers: {
            fetch: function() { return {then: angular.noop}; }
          }
        },
        link: {
          addWatcher: {
            fetch: function() { return {then: angular.noop}; }
          }
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
        latestTab: {},
        I18n: I18n,
        ConfigurationService: {
          commentsSortedInDescendingOrder: function() {
            return false;
          }
        },
        UserService: UserService,
        CustomFieldHelper: CustomFieldHelper,
        WorkPackagesDetailsHelper: {
          attachmentsTitle: function() { return ''; }
        },
        workPackage: buildWorkPackageWithId(workPackageId),
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
          expect(fetchPresentPropertiesWithName('date')[0].value).to.equal(placeholder + ' - Jul 10, 2014');
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
          expect(fetchPresentPropertiesWithName('date')[0].value).to.equal('Jul 9, 2014 - ' + placeholder);
        });
      });

      describe('when both - start and due date are present', function() {
        beforeEach(function() {
          workPackage.props.startDate = startDate;
          workPackage.props.dueDate = dueDate;

          buildController();
        });

        it('combines them and renders them as date property', function() {
          expect(fetchPresentPropertiesWithName('date')[0].value).to.equal('Jul 9, 2014 - Jul 10, 2014');
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

      describe('relations', function() {
        beforeEach(function() {
          buildController();
        });

        it('Relation::Relates', function() {
          expect(scope.relatedTo.length).to.eq(1);
        });
      });
    });
  });


});
