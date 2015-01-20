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

describe('Work Package Relations Directive', function() {
  var I18n, PathHelper, WorkPackagesHelper, Ajax, compile, element, scope, ChildrenRelationsHandler, stateParams = {};

  beforeEach(angular.mock.module('openproject.workPackages.tabs',
                                 'openproject.api',
                                 'openproject.helpers',
                                 'openproject.models',
                                 'openproject.layout',
                                 'openproject.services',
                                 'openproject.viewModels',
                                 'ngSanitize'));

  beforeEach(module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', function() { return configurationService; });
  }));

  beforeEach(inject(function($rootScope,
                             $compile,
                             _I18n_,
                             _PathHelper_,
                             _WorkPackagesHelper_,
                             _ChildrenRelationsHandler_) {
    scope = $rootScope.$new();

    compile = function(html) {
      element = $compile(html)(scope);
      scope.$digest();
    };

    I18n = _I18n_;
    ChildrenRelationsHandler = _ChildrenRelationsHandler_;
    PathHelper = _PathHelper_;
    WorkPackagesHelper = _WorkPackagesHelper_;

    Ajax = {
      Autocompleter: angular.noop
    };

    var stub = sinon.stub(I18n, 't');

    stub.withArgs('js.work_packages.properties.subject').returns('Column0');
    stub.withArgs('js.work_packages.properties.status').returns('Column1');
    stub.withArgs('js.work_packages.properties.assignee').returns('Column2');
    stub.withArgs('js.relations.delete').returns('Delete relation');
  }));

  afterEach(function() {
    I18n.t.restore();
  });

  var html = "<work-package-relations title='MyRelation' handler='relations' button-title='Add Relation' button-icon='%MyIcon%'></work-package-relations>";

  var workPackage1;
  var workPackage2;
  var workPackage3;
  var workPackage4;

  var relation1, relation2, relation3;

  var relationsHandlerEmpty;
  var relationsHandlerSingle;
  var relationsHandlerMulti;
  var relationsHandlerWithNotAssignedRelatedWorkPackage;

  var createRelationsHandlerStub = function($timeout, count) {
    var relationsHandler = {};

    relationsHandler.relationsId = sinon.stub();
    relationsHandler.isEmpty = sinon.stub();
    relationsHandler.getCount = sinon.stub();
    relationsHandler.canAddRelation = sinon.stub();
    relationsHandler.canDeleteRelation = sinon.stub();
    relationsHandler.addRelation = sinon.stub();
    relationsHandler.applyCustomExtensions = sinon.stub();

    relationsHandler.workPackage = workPackage1;
    relationsHandler.relationsId.returns('related');
    relationsHandler.isEmpty.returns(count === 0);
    relationsHandler.getCount.returns(count);

    relationsHandler.type = "relation";

    relationsHandler.getRelatedWorkPackage = function() {
      return $timeout(function() {
        return workPackage1;
      }, 10);
    };

    return relationsHandler;
  };

  beforeEach(inject(function($q, $timeout) {
    workPackage1 = {
      props: {
        id: "1",
        subject: "Subject 1",
      },
      embedded: {
        status: {
          props: {
            name: 'Status 1',
            isClosed: false
          }
        },
        assignee: {
          props: {
            name: "Assignee 1",
          }
        }
      },
      links: {
        self: { href: "/work_packages/1" },
        addChild: {href: "/add_children_href"},
        addRelation: { href: "/work_packages/1/relations" }
      }
    };
    workPackage2 = {
      props: {
        id: "2",
        subject: "Subject 2",
      },
      embedded: {
        status: {
          props: {
            name: 'Status 2',
            isClosed: false
          }
        },
        assignee: {
          props: {
            name: "Assignee 2",
          }
        }
      },
      links: {
        self: { href: "/work_packages/1" }
      }
    };
    workPackage3 = {
      props: {
        id: "3",
        subject: "Subject 3",
      },
      embedded: {
        status: {
          props: {
            name: 'Status 2',
            isClosed: true
          }
        },
        assignee: {
          props: {
            name: "Assignee 3",
          }
        }
      },
      links: {
        self: { href: "/work_packages/1" }
      }
    };
    workPackage4 = {
      props: {
        id: "4",
        subject: "Subject 4",
      },
      embedded: {
        status: {
          props: {
            name: 'Status 4',
            isClosed: false
          }
        }
      },
      links: {
        self: { href: "/work_packages/1" }
      }
    };
    relation1 = {
      links: {
        self: { href: "/relations/1" },
        remove: { href: "/relations/1" },
        relatedTo: {
          href: "/work_packages/1"
        },
        relatedFrom: {
          href: "/work_packages/3"
        }
      }
    };
    relation2 = {
      links: {
        self: { href: "/relations/2" },
        relatedTo: {
          href: "/work_packages/3"
        },
        relatedFrom: {
          href: "/work_packages/1"
        }
      }
    };
    relation3 = {
      links: {
        self: { href: "/relations/3" },
        relatedTo: {
          href: "/work_packages/4"
        },
        relatedFrom: {
          href: "/work_packages/1"
        }
      }
    };

    relationsHandlerEmpty = createRelationsHandlerStub($timeout, 0);
    relationsHandlerEmpty.relations = [];

    relationsHandlerSingle = createRelationsHandlerStub($timeout, 1);
    relationsHandlerSingle.relations = [relation1];

    relationsHandlerMulti = createRelationsHandlerStub($timeout, 2);
    relationsHandlerMulti.relations = [relation1, relation2];

    relationsHandlerWithNotAssignedRelatedWorkPackage = createRelationsHandlerStub($timeout, 1);
    relationsHandlerWithNotAssignedRelatedWorkPackage.relations = [relation3];
  }));

  var shouldBehaveLikeRelationsDirective = function() {
    it('should have a title', function() {
      var title = angular.element(element.find('h3'));

      expect(title.text()).to.include('MyRelation');
    });
  };

  var shouldBehaveLikeHasTableHeader = function() {
    it('should have a table head', function() {
      var column0 = angular.element(element.find('.workpackages table thead td:nth-child(1)'));
      var column1 = angular.element(element.find('.workpackages table thead td:nth-child(2)'));
      var column2 = angular.element(element.find('.workpackages table thead td:nth-child(3)'));

      expect(angular.element(column0).text()).to.eq(I18n.t('js.work_packages.properties.subject'));
      expect(angular.element(column1).text()).to.eq(I18n.t('js.work_packages.properties.status'));
      expect(angular.element(column2).text()).to.eq(I18n.t('js.work_packages.properties.assignee'));
    });
  };

  var shouldBehaveLikeHasTableContent = function(count, removable) {
    it('should have table content', function() {
      for (var x = 1; x <= count; x++) {
        var column0 = angular.element(element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(1)'));
        var column1 = angular.element(element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(2)'));
        var column2 = angular.element(element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(3)'));

        expect(angular.element(column0).text()).to.include('Subject ' + x);
        expect(angular.element(column1).text()).to.include('Status ' + x);
        expect(angular.element(column2).text()).to.include('Assignee ' + x);

        expect(angular.element(column0).find('a').hasClass('work_package')).to.be.true;
        expect(angular.element(column0).find('a').hasClass('closed')).to.be.false;

        if(removable) {
          var column4 = angular.element(element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(4)'));
          var deleteIcon = angular.element(column4.find('span.icon-delete'));
          expect(deleteIcon.length).not.to.eq(0);
          expect(deleteIcon.attr('title')).to.include('Delete relation');
        }
      }
    });
  };

  var shouldBehaveLikeCollapsedRelationsDirective = function() {

    shouldBehaveLikeRelationsDirective();

    it('should be initially collapsed', function() {
      var content = angular.element(element.find('div.content'));
      expect(content.hasClass('ng-hide')).to.eq(true);
    });
  };

  var shouldBehaveLikeExpandedRelationsDirective = function() {

    shouldBehaveLikeRelationsDirective();

    it('should be initially expanded', function() {
      var content = angular.element(element.find('div.content'));
      expect(content.hasClass('ng-hide')).to.eq(false);
    });
  };

  var shouldBehaveLikeSingleRelationDirective = function() {
    it('should NOT have an elements count', function() {
      var title = angular.element(element.find('h3'));

      expect(title.text()).to.not.include('(' + scope.relations.getCount() + ')');
    });
  };

  var shouldBehaveLikeMultiRelationDirective = function() {
    it('should have an elements count', function() {
      var title = angular.element(element.find('h3'));

      expect(title.text()).to.include('(' + scope.relations.getCount() + ')');
    });
  };

  var shouldBehaveLikeHasAddRelationDialog = function() {
    it('should have add relation button and id input', function() {
      var addRelationDiv = angular.element(element.find('.content .add-relation'));
      expect(addRelationDiv.length).not.to.eq(0);

      var button = addRelationDiv.find('button');
      expect(button.attr('title')).to.include('Add Relation');
      expect(button.text()).to.include('Add Relation');
    });
  };

  var shouldBehaveLikeReadOnlyRelationDialog = function() {
    it('should have add relation button and id input', function() {
      var addRelationDiv = angular.element(element.find('.workpackages .add-relation'));

      expect(addRelationDiv.length).to.eq(0);
    });
  };

  describe('children relation', function() {
    context('add child link present', function() {
      beforeEach(function() {
        scope.relations = new ChildrenRelationsHandler(workPackage1, []);
        compile(html);
      });
      it('"add child" button should be present', function() {
        expect(angular.element(element.find('.add-work-package-child-button')).length).to.eql(1);
      });
    });

    context('add child link missing', function() {
      beforeEach(function() {
        scope.relations = new ChildrenRelationsHandler(workPackage2, []);
        compile(html);
      });
      it('"add child" button should be missing', function() {
        expect(angular.element(element.find('.add-work-package-child-button')).length).to.eql(0);
      });
    });
  });

  describe('no element markup', function() {
    beforeEach(function() {
      scope.relations = relationsHandlerMulti;

      scope.relations.canAddRelation.returns(true);
      scope.relations.isEmpty.returns(true);

      compile(html);
    });

    shouldBehaveLikeMultiRelationDirective();

    shouldBehaveLikeCollapsedRelationsDirective();

    shouldBehaveLikeHasAddRelationDialog();
  });

  describe('single element markup', function() {
    describe('header', function() {
      beforeEach(inject(function($timeout) {
        scope.relations = relationsHandlerSingle;
        scope.relations.isSingletonRelation = true;

        compile(html);

        $timeout.flush();
      }));

      shouldBehaveLikeSingleRelationDirective();
    });

    describe('readonly', function() {
      beforeEach(inject(function($timeout) {
        scope.relations = relationsHandlerSingle;
        scope.relations.canDeleteRelation.returns(true);

        compile(html);

        $timeout.flush();
      }));

      shouldBehaveLikeRelationsDirective();

      shouldBehaveLikeExpandedRelationsDirective();

      shouldBehaveLikeHasTableHeader();

      shouldBehaveLikeHasTableContent(1, true);

      shouldBehaveLikeReadOnlyRelationDialog();
    });

    describe('can add and remove relations', function() {
      beforeEach(inject(function($timeout) {
        scope.relations = relationsHandlerSingle;
        scope.relations.relations = [relation2];
        scope.relations.canAddRelation.returns(true);
        scope.relations.canDeleteRelation.returns(false);

        compile(html);

        $timeout.flush();
      }));

      shouldBehaveLikeRelationsDirective();

      shouldBehaveLikeExpandedRelationsDirective();

      shouldBehaveLikeHasTableHeader();

      shouldBehaveLikeHasTableContent(1, false);

      shouldBehaveLikeHasAddRelationDialog();
    });

    describe('table row of closed work package', function() {
      beforeEach(inject(function($timeout) {
        scope.relations = relationsHandlerSingle;
        scope.relations.relations = [relation2];

        scope.relations.getRelatedWorkPackage = function() {
          return $timeout(function() {
            return workPackage3;
          }, 10);
        };

        compile(html);

        $timeout.flush();
      }));

      it('should have css class closed', function() {
        var closedWorkPackageRow = angular.element(element.find('.workpackages table tbody tr:nth-of-type(1) td:nth-child(1) a'));

        expect(closedWorkPackageRow.hasClass('closed')).to.be.true;
      });
    });

    describe('table row of work package that is not assigned', function() {
      var row;

      beforeEach(inject(function($timeout) {
        scope.relations = relationsHandlerWithNotAssignedRelatedWorkPackage;

        scope.relations.getRelatedWorkPackage = function() {
          return $timeout(function() {
            return workPackage4;
          }, 10);
        };

        compile(html);

        $timeout.flush();

        row = angular.element(element.find('.workpackages table tbody tr:nth-of-type(1)'));
      }));

      it('should NOT have link', function() {
        expect(row.find('td:nth-of-type(2) a').length).to.eql(0);
      });

      it('should have empty element tag', function() {
        expect(row.find('empty-element').text()).to.include('-');
      });
    });
  });

  // describe('multi element markup', function() {
  //   beforeEach(inject(function($timeout) {
  //     scope.workPackage = workPackage1;
  //     scope.relations = [relation1, relation2];

  //     compile(multiElementHtml);

  //     $timeout.flush();
  //   }));

  //   shouldBehaveLikeRelationsDirective();

  //   shouldBehaveLikeMultiRelationDirective();

  //   shouldBehaveLikeExpandedRelationsDirective();

  //   shouldBehaveLikeHasTableHeader();

  //   shouldBehaveLikeHasTableContent(2);
  // });
});
