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

describe('Work Package Relations Directive', function() {
  var I18n, PathHelper, compile, element, scope;

  beforeEach(angular.mock.module('openproject.workPackages.tabs', 'openproject.api', 'openproject.helpers', 'ngSanitize'));
  beforeEach(module('templates', function($provide) {
  }));

  beforeEach(inject(function($rootScope, $compile, _I18n_, _PathHelper_, _WorkPackagesHelper_) {
    scope = $rootScope.$new();

    compile = function(html) {
      element = $compile(html)(scope);
      scope.$digest();
    };

    I18n = _I18n_;
    PathHelper = _PathHelper_;
    WorkPackagesHelper = _WorkPackagesHelper_;
    Ajax = {
      Autocompleter: angular.noop
    }

    var stub = sinon.stub(I18n, 't');

    stub.withArgs('js.work_packages.properties.subject').returns('Column0');
    stub.withArgs('js.work_packages.properties.status').returns('Column1');
    stub.withArgs('js.work_packages.properties.assignee').returns('Column2');
  }));

  afterEach(function() {
    I18n.t.restore();
  });

  var multiElementHtml = "<work-package-relations title='MyRelation' work-package='workPackage' relations='relations' button-title='Add Relation' button-icon='%MyIcon%'></work-package-relation>"
  var singleElementHtml = "<work-package-relations title='MyRelation' work-package='workPackage' relations='relations' button-title='Add Relation' button-icon='%MyIcon%' singleton-relation='true'></work-package-relation>"


  var workPackage1;
  var workPackage2;

  beforeEach(inject(function($q, $timeout) {
    workPackage1 = {
      props: {
        id: "1",
        subject: "Subject 1",
        status: "Status 1"
      },
      embedded: {
        assignee: {
          props: {
            name: "Assignee 1",
          }
        }
      },
      links: {
        self: { href: "/work_packages/1" }
      }
    };
    workPackage2 = {
      props: {
        id: "2",
        subject: "Subject 2",
        status: "Status 2"
      },
      embedded: {
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
        status: "Status 3"
      },
      embedded: {
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
    relation1 = {
      links: {
        self: { href: "/relations/1" },
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

    WorkPackagesHelper.getRelatedWorkPackage = function() {
      return $timeout(function() {
        return workPackage1;
      }, 10);
    };

  }));

  var shouldBehaveLikeRelationsDirective = function() {
    it('should have a title', function() {
      var title = angular.element(element.find('h3'));

      expect(title.text()).to.include('MyRelation');
    });

    //it('should have a button', function() {
    //  var button = angular.element(element.find('button.button'));

    //  expect(button.attr('title')).to.include('Add Relation');
    //  expect(button.text()).to.include('Add Relation');
    //  expect(button.text()).to.include('%MyIcon%');
    //});
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

  var shouldBehaveLikeHasTableContent = function(count) {
    it('should have table content', function() {
      for (var x = 1; x <= count; x++) {
        var column0 = angular.element(element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(1)'));
        var column1 = angular.element(element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(2)'));
        var column2 = angular.element(element.find('.workpackages table tbody tr:nth-of-type(' + x + ') td:nth-child(3)'));

        expect(angular.element(column0).text()).to.include('Subject ' + x);
        expect(angular.element(column1).text()).to.include('Status ' + x);
        expect(angular.element(column2).text()).to.include('Assignee ' + x);
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
    it('should not have an elements count', function() {
      var title = angular.element(element.find('h3'));

      expect(title.text()).not.to.include('(');
      expect(title.text()).not.to.include(')');
    });
  };

  var shouldBehaveLikeMultiRelationDirective = function() {
    it('should have an elements count', function() {
      var title = angular.element(element.find('h3'));

      expect(title.text()).to.include('(' + scope.relations.length + ')');
    });
  };

  describe('no element markup', function() {
    describe('single element behavior', function() {
      beforeEach(function() {
        compile(singleElementHtml);
      });

      shouldBehaveLikeSingleRelationDirective();

      shouldBehaveLikeCollapsedRelationsDirective();
    });

    describe('multi element behavior', function() {
      beforeEach(function() {
        scope.relations = [];

        compile(multiElementHtml);
      });

      shouldBehaveLikeMultiRelationDirective();

      shouldBehaveLikeCollapsedRelationsDirective();
    });
  });

  describe('single element markup', function() {
    beforeEach(inject(function($timeout) {
      scope.workPackage = workPackage2;
      scope.relations = [relation1];

      compile(singleElementHtml);

      $timeout.flush();
    }));

    shouldBehaveLikeRelationsDirective();

    shouldBehaveLikeSingleRelationDirective();

    shouldBehaveLikeExpandedRelationsDirective();

    shouldBehaveLikeHasTableHeader();

    shouldBehaveLikeHasTableContent(1);
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
