//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

var reactivestates = require("reactivestates");

describe('optionsDropdown Directive', function() {
  var compile,
      element,
      rootScope,
      scope,
      I18n,
      AuthorisationService,
      wpTableSum,
      wpTableGroupBy,
      columnsModal,
      sortByModal,
      groupByModal,
      exportModal,
      wpTableHierarchies,
      states,
      query,
      form;

  beforeEach(angular.mock.module('openproject.models',
                    'openproject.workPackages',
                    'openproject.api',
                    'openproject.layout',
                    'openproject.services'));

  beforeEach(angular.mock.module('openproject.templates', function($provide) {
    wpTableSum = {
      isEnabled: false
    };

    wpTableHierarchies = {
      isEnabled: false
    };

    wpTableGroupBy = {
      isEnabled: false
    }

    columnsModal = {};
    sortByModal = {};
    groupByModal = {};
    exportModal = {};

    query = {
      id: 5
    };

    var queryValues = {
      takeUntil: function(condition) {
        return {
          subscribe: function(func) {
            func(query);
          }
        }
      }
    };

    form = {}

    var formValues = {
      takeUntil: function(condition) {
        return {
          subscribe: function(func) {
            func(form);
          }
        }
      }
    };

    states = {
      query: {
        resource: {
          values$: function() {
                     return queryValues;
                   }
        },
        form: {
          values$: function() {
                     return formValues;
                   }
        }

      },
      table: {
        stopAllSubscriptions: [false]
      }
    };

    $provide.constant('wpTableSum', wpTableSum);
    $provide.constant('wpTableHierarchies', wpTableHierarchies);
    $provide.constant('wpTableGroupBy', wpTableGroupBy);
    $provide.constant('columnsModal', columnsModal);
    $provide.constant('sortingModal', sortByModal);
    $provide.constant('groupingModal', groupByModal);
    $provide.constant('exportModal', exportModal);
    $provide.constant('states', states);
  }));

  beforeEach(inject(function($rootScope, $compile) {
    var optionsDropdownHtml;
    optionsDropdownHtml = '<div class="toolbar"><button has-dropdown-menu="" target="SettingsDropdownMenu" locals="query"></button></div>';

    element = angular.element(optionsDropdownHtml);
    rootScope = $rootScope;
    scope = $rootScope.$new();
    compile = function() {
      angular.element(document).find('body').append(element);
      $compile(element)(scope);
      element.find('button').click();
      scope.$apply();
    };
  }));

  beforeEach(inject(function(_AuthorisationService_, _I18n_){
    AuthorisationService = _AuthorisationService_;

    I18n = _I18n_;

    var stub = sinon.stub(I18n, 't');

    stub.withArgs('js.label_save_as').returns('Save as');
    stub.withArgs('js.toolbar.settings.columns').returns('Columns ...');
    stub.withArgs('js.toolbar.settings.sort_by').returns('Sort by ...');
    stub.withArgs('js.toolbar.settings.group_by').returns('Group by ...');
    stub.withArgs('js.toolbar.settings.display_sums').returns('Display sums');
    stub.withArgs('js.toolbar.settings.hide_sums').returns('Hide sums');
    stub.withArgs('js.toolbar.settings.display_hierarchy').returns('Display hierarchy');
    stub.withArgs('js.toolbar.settings.hide_hierarchy').returns('Hide hierarchy');
    stub.withArgs('js.toolbar.settings.export').returns('Export ...');
  }));

  afterEach(function() {
    I18n.t.restore();
    element.remove();
  });

  describe('element', function() {
    var getMenuItem = function(name) {
      var menuLinks = element.find('a.menu-item');

      return _.find(menuLinks, function(item) {
        return angular.element(item).text().indexOf(name) !== -1 ||
               angular.element(item).find('span').text().indexOf(name) !== -1;
      });
    }

    it('should render a div', function() {
      expect(element.prop('tagName')).to.equal('DIV');
    });

    describe('Columns', function() {
      var getColumnsMenuItem = function() {
        return getMenuItem(I18n.t('js.toolbar.settings.columns'));
      }

      it('has a "Columns" menu item', function() {
        compile();

        var item = getColumnsMenuItem();

        expect(!!item).to.be.true;
      });

      it('activates the columns modal on click', function() {
        compile();

        var item = getColumnsMenuItem();

        var spy = sinon.spy();

        columnsModal['activate'] = spy;

        angular.element(item).click();

        expect(spy).to.have.been.calledWith();
      });
    })

    describe('Sort by', function() {
      var getSortByMenuItem = function() {
        return getMenuItem(I18n.t('js.toolbar.settings.sort_by'));
      };

      it('has a "Sort by" menu item', function() {
        compile();

        var item = getSortByMenuItem();

        expect(!!item).to.be.true;
      });

      it('activates the columns modal on click', function() {
        compile();

        var item = getSortByMenuItem();

        var spy = sinon.spy();

        sortByModal['activate'] = spy;

        angular.element(item).click();

        expect(spy).to.have.been.calledWith();
      });
    })

    describe('Group by', function() {
      var getGroupByMenuItem = function() {
        return getMenuItem(I18n.t('js.toolbar.settings.group_by'));
      };

      it('has a "Group by" menu item', function() {
        compile();

        var item = getGroupByMenuItem();

        expect(!!item).to.be.true;
      });

      it('activates the columns modal on click', function() {
        compile();

        var item = getGroupByMenuItem();

        var spy = sinon.spy();

        groupByModal['activate'] = spy;

        angular.element(item).click();

        expect(spy).to.have.been.calledWith();
      });
    })

    describe('sums', function() {
      var getSumsMenuItem = function() {
        return getMenuItem(I18n.t('js.toolbar.settings.display_sums'));
      }

      it('has a "sums" menu item', function() {
        compile();

        var item = getSumsMenuItem();

        expect(!!item).to.be.true;
      });

      it('displays not sumed', function() {
        compile();

        var item = getSumsMenuItem();

        expect(angular.element(item).find('.no-icon').length).to.eq(1);
      });

      it('displays sumed if the service tells it to', function() {
        wpTableSum['isEnabled'] = true;

        compile();

        var item = getSumsMenuItem();

        expect(angular.element(item).find('.icon-checkmark').length).to.eq(1);
      });

      it('forwards to the service on click', function() {
        compile();

        var item = getSumsMenuItem();

        var spy = sinon.spy();

        wpTableSum['toggle'] = spy;

        angular.element(item).click();

        expect(spy).to.have.been.calledWith();
      });
    });

    describe('hierarchy', function() {
      var getHierarchyMenuItem = function() {
        return getMenuItem(I18n.t('js.toolbar.settings.display_hierarchy'));
      }

      it('has a "hierarchy" menu item', function() {
        compile();

        var item = getHierarchyMenuItem();

        expect(!!item).to.be.true;
      });

      it('displays not active', function() {
        compile();

        var item = getHierarchyMenuItem();

        expect(angular.element(item).find('.icon-no-hierarchy').length).to.eq(1);
      });

      it('displays active if the service tells it to', function() {
        wpTableHierarchies['isEnabled'] = true;

        compile();

        // named differently if active
        var item = getMenuItem(I18n.t('js.toolbar.settings.hide_hierarchy'));

        expect(angular.element(item).find('.icon-hierarchy').length).to.eq(1);
      });

      it('forwards to the service on click', function() {
        compile();

        var item = getHierarchyMenuItem();

        var spy = sinon.spy();

        wpTableHierarchies['setEnabled'] = spy;

        angular.element(item).click();

        expect(spy).to.have.been.calledWith(true);
      });
    });

    describe('Export', function() {
      var getExportMenuItem = function() {
        return getMenuItem(I18n.t('js.toolbar.settings.export'));
      }

      var authorisation;

      beforeEach(function() {
        authorisation = sinon.stub(AuthorisationService, 'can');
        authorisation.returns(false);
      });

      afterEach(function() {
        AuthorisationService.can.restore();
      });

      it('has a "Export" menu item', function() {
        compile();

        var item = getExportMenuItem();

        expect(!!item).to.be.true;
      });

      it('activates the export modal on click', function() {
        authorisation.withArgs('work_packages', 'representations').returns(true);

        compile();

        var item = getExportMenuItem();

        var spy = sinon.spy();

        exportModal['activate'] = spy;

        angular.element(item).click();

        expect(spy).to.have.been.calledWith();
      });

      it('is inactive when permissions are lacking', function() {
        compile();

        var item = getExportMenuItem();

        expect(angular.element(item).filter('.inactive').length).to.eq(1);
      });
    })
  });
});
