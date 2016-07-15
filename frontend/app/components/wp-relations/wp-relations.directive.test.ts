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


import {wpTabsModule, opApiModule} from '../../angular-modules';
const expect = chai.expect;

describe('Work Package Relations Directive', () => {
  var $q;
  var I18n;
  var compile;
  var element;
  var scope;
  var stateParams = {};
  var WorkPackageChildRelationsGroup;

  var workPackage;
  var relation;
  var relationGroupMock;
  var canAdd;
  var canRemove;

  beforeEach(angular.mock.module(
    wpTabsModule.name,
    opApiModule.name,
    'openproject.helpers',
    'openproject.models',
    'openproject.layout',
    'openproject.services',
    'openproject.viewModels',
    'ngSanitize'));

  beforeEach(angular.mock.module('openproject.templates', function ($provide) {
    var configurationService = {
      isTimezoneSet: sinon.stub().returns(false),
      accessibilityModeEnabled: sinon.stub().returns(false)
    };

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(angular.mock.inject(($rootScope,
                                  $compile,
                                  _$q_,
                                  _I18n_,
                                  _WorkPackageChildRelationsGroup_) => {
    $q = _$q_;
    I18n = _I18n_;
    WorkPackageChildRelationsGroup = _WorkPackageChildRelationsGroup_;

    scope = $rootScope.$new();

    compile = html => {
      element = $compile(html)(scope);
      scope.$digest();
    };

    relation = {
      subject: 'Subject 1',
      assignee: {
        name: 'Assignee 1'
      },
      status: {
        name: 'Status 1',
        isClosed: false
      },
      $load: () => $q.when(relation)
    };
    workPackage = {};
    canAdd = true;
    canRemove = true;
    relationGroupMock = {
      id: 'parent',
      type: 'parent',
      name: 'parent',
      relations: [relation],
      getRelatedWorkPackage: () => relation.$load(),
      canAddRelation: () => canAdd,
      canRemoveRelation: () => canRemove,
      isEmpty: false,
    };

    var stub = sinon.stub(I18n, 't');
    stub.withArgs('js.work_packages.properties.subject').returns('Subject');
    stub.withArgs('js.work_packages.properties.status').returns('Status');
    stub.withArgs('js.work_packages.properties.assignee').returns('Assignee');
    stub.withArgs('js.relations.remove').returns('Remove relation');
    stub.withArgs('js.relation_labels.parent').returns('Parent');
    stub.withArgs('js.relation_labels.something').returns('Something');
  }));

  afterEach(() => {
    I18n.t.restore();
  });

  var html = `<wp-relations relation-group="relationGroup"
                            button-title="'Add Relation'"></wp-relations>`;

  var shouldBehaveLikeRelationsDirective = () => {
    it('should have a title', () => {
      const title = angular.element(element.find('h3'));
      const text = relationGroupMock.id === 'something' ? 'Something' : 'Parent';
      expect(title.text()).to.include(text);
    });
  };

  var shouldBehaveLikeHasTableHeader = () => {
    it('should have a table head', () => {
      var column0 = angular.element(element.find('.workpackages table thead th:nth-child(1)'));
      var column1 = angular.element(element.find('.workpackages table thead th:nth-child(2)'));
      var column2 = angular.element(element.find('.workpackages table thead th:nth-child(3)'));

      expect(angular.element(column0).text()).to.eq(I18n.t('js.work_packages.properties.subject'));
      expect(angular.element(column1).text()).to.eq(I18n.t('js.work_packages.properties.status'));
      expect(angular.element(column2).text()).to.eq(I18n.t('js.work_packages.properties.assignee'));
    });
  };

  var shouldBehaveLikeHasTableContent = (removable) => {
    it('should have table content', () => {
      let x = 1;
      var column0 = element.find('.workpackages tr:nth-of-type(' + x + ') td:nth-child(1)');
      var column1 = element.find('.workpackages tr:nth-of-type(' + x + ') td:nth-child(2)');
      var column2 = element.find('.workpackages tr:nth-of-type(' + x + ') td:nth-child(3)');

      expect(column0.text()).to.include('Subject ' + x);
      expect(column1.text()).to.include('Status ' + x);
      expect(column2.text()).to.include('Assignee ' + x);

      expect(column0.find('a').hasClass('work_package')).to.be.true;
      expect(column0.find('a').hasClass('closed')).to.be.false;

      if (removable) {
        const column4 = element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(4)');
        const removeIcon = column4.find('span.icon-remove');
        expect(removeIcon.length).not.to.eq(0);
        expect(removeIcon.attr('title')).to.include('Remove relation');
      }
    });
  };

  var shouldBehaveLikeCollapsedRelationsDirective = () => {

    shouldBehaveLikeRelationsDirective();

    it('should be initially collapsed', () => {
      var content = angular.element(element.find('div.content'));
      expect(content.hasClass('ng-if')).to.eq(false);
    });
  };

  var shouldBehaveLikeExpandedRelationsDirective = () => {

    shouldBehaveLikeRelationsDirective();

    it('should be initially expanded', () => {
      var content = angular.element(element.find('div.content'));
      expect(content.hasClass('ng-hide')).to.eq(false);
    });
  };

  var shouldBehaveLikeSingleRelationDirective = () => {
    it('should NOT have an elements count', () => {
      let len = scope.relationGroup.length;
      expect(element.find('h3').text()).to.not.include('(' + len + ')');
    });
  };

  var shouldBehaveLikeMultiRelationDirective = () => {
    it('should have an elements count', () => {
      let len = scope.relationGroup.relations.length;
      expect(element.find('h3').text()).to.include('(' + len + ')');
    });
  };

  var shouldBehaveLikeHasAddRelationDialog = () => {
    it('should have an add relation button and id input', () => {
      const addRelationDiv = element.find('.content .add-relation');
      const button = addRelationDiv.find('button');

      expect(addRelationDiv).not.to.eq(0);
      expect(button.attr('title')).to.include('Add Relation');
      expect(button.text()).to.include('Add Relation');
    });
  };

  var shouldBehaveLikeReadOnlyRelationDialog = () => {
    it('should have no add relation button and id input', () => {
      var addRelationDiv = element.find('.workpackages .add-relation');
      expect(addRelationDiv.length).to.eq(0);
    });
  };

  describe('when having child relations', () => {
    var childGroupConfig;

    beforeEach(() => {
      childGroupConfig = {
        name: 'children',
        type: 'children'
      };
    });

    context('when it is possible to add a child relation', () => {
      beforeEach(() => {
        workPackage = {
          addChild: true,
          children: [relation],
        };
        scope.relationGroup =
          new WorkPackageChildRelationsGroup(workPackage, childGroupConfig);

        compile(html);
      });

      it('should have an "add child" button', () => {
        expect(element.find('.add-work-package-child-button').length).to.eq(1);
      });
    });

    context('when it is not possible to add a child relation', () => {
      beforeEach(() => {
        scope.relationGroup =
          new WorkPackageChildRelationsGroup({}, childGroupConfig);
        compile(html);
      });

      it('should have no add child link', () => {
        expect(angular.element(element.find('.add-work-package-child-button')).length).to.eq(0);
      });
    });
  });

  describe('when there is no element markup', () => {
    beforeEach(() => {
      canAdd = true;
      relationGroupMock.id = 'something';
      scope.relationGroup = relationGroupMock;

      compile(html);
    });

    shouldBehaveLikeMultiRelationDirective();
    shouldBehaveLikeCollapsedRelationsDirective();
    shouldBehaveLikeHasAddRelationDialog();
  });

  describe('single element markup', () => {
    describe('header', () => {
      beforeEach(() => {
        scope.relationGroup = relationGroupMock;
        compile(html);
      });

      shouldBehaveLikeSingleRelationDirective();
    });

    describe('when it is readonly', () => {
      beforeEach(() => {
        canRemove = true;
        scope.relationGroup = relationGroupMock;
        compile(html);
      });

      shouldBehaveLikeRelationsDirective();
      shouldBehaveLikeExpandedRelationsDirective();
      shouldBehaveLikeHasTableHeader();
      shouldBehaveLikeHasTableContent(true);
      shouldBehaveLikeReadOnlyRelationDialog();
    });

    describe('when it is possible to add and remove relations', () => {
      beforeEach(() => {
        scope.relationGroup = relationGroupMock;
        compile(html);
      });

      shouldBehaveLikeRelationsDirective();
      shouldBehaveLikeExpandedRelationsDirective();
      shouldBehaveLikeHasTableHeader();
      shouldBehaveLikeHasTableContent(false);
      shouldBehaveLikeHasAddRelationDialog();
    });

    describe('when the work package is closed', () => {
      beforeEach(() => {
        relation.status.isClosed = true;
        scope.relationGroup = relationGroupMock;
        compile(html);
      });

      it('should have set the css class of the row to closed', () => {
        var closedWorkPackageRow = element.find('.workpackages tr:nth-of-type(1) td:nth-child(1) a');
        expect(closedWorkPackageRow.hasClass('closed')).to.be.true;
      });
    });

    describe('when a table row has no work package assigned', () => {
      var row;

      beforeEach(() => {
        relation.assignee = null;
        scope.relationGroup = relationGroupMock;

        compile(html);
        row = element.find('.workpackages tr:nth-of-type(1)');
      });

      it('should NOT have link', () => {
        expect(row.find('td:nth-of-type(2) a').length).to.eql(0);
      });

      it('should have empty element tag', () => {
        expect(row.find('empty-element').text()).to.include('-');
      });
    });
  });
});
