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

describe('workPackageDetailsToolbar', function() {
  var I18n:any, $q:any, HookService:any, compile:any, scope:any, element:any, stateParams:any;
  var html = `
    <div id="content">
      <wp-details-toolbar work-package='workPackage'></wp-details-toolbar>
    </div>`;
  stateParams = {};


  beforeEach(angular.mock.module('ui.router',
                    'openproject',
                    'openproject.workPackages.controllers',
                    'openproject.workPackages.services',
                    'openproject.uiComponents',
                    'openproject.workPackages',
                    'openproject.api',
                    'openproject.models',
                    'openproject.layout',
                    'openproject.services',
                    'openproject.uiComponents',
                    'openproject.templates'
                    ));

  beforeEach(angular.mock.module('openproject.templates', function($provide:ng.auto.IProvideService) {
    var configurationService:any = {};

    configurationService.accessibilityModeEnabled = sinon.stub().returns(false);
    configurationService.warnOnLeavingUnsaved = sinon.stub().returns(false);

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(inject(function($rootScope:any,
                             $compile:any,
                             ConfigurationService:any,
                             _I18n_:any,
                             _HookService_:any,
                             _$q_:any) {
    $q = _$q_;
    I18n = _I18n_;
    HookService = _HookService_;
    var stub = sinon.stub(I18n, 't');

    ConfigurationService.api = sinon.stub().returns($q.reject());

    stub.withArgs('js.button_log_time').returns('Log time');
    stub.withArgs('js.button_move').returns('Move');
    stub.withArgs('js.button_delete').returns('Delete');

    stub.withArgs('js.button_plugin_action_1').returns('plugin_action_1');
    stub.withArgs('js.button_plugin_action_2').returns('plugin_action_2');

    scope = $rootScope.$new();

    compile = function() {
      element = $compile(element)(scope);
      angular.element(document.body).append(element);
      scope.$apply();

      element.find('button:eq(0)').click();
      scope.$apply();
    };

  }));

  afterEach(function() {
    I18n.t.restore();
    element.remove();
  });

  var pluginActions:any = {
    plugin_action_1: { key: 'plugin_action_1',
                       resource: 'workPackage',
                       link: 'plugin_action_1',
                       css: ['plugin_action_1_css_1', 'plugin_action_1_css_2'] },
    plugin_action_2: { key: 'plugin_action_2',
                       resource: 'workPackage',
                       link: 'plugin_action_2',
                       css: ['plugin_action_2_css_1'] }
  };

  beforeEach(function() {
    var workPackage = {
      logTime: { href: 'log_timeMeLink' },
      duplicate: { href: 'duplicateMeLink' },
      move: { href: 'moveMeLink' },
      delete: { href: 'deleteMeLink' },
      plugin_action_1: { href: 'plugin_actionMeLink' },
      plugin_action_2: { href: 'plugin_actionMeLink' },
      project: {
        $load: function() { return $q.when(true) },
        createWorkPackage: { href: 'createWorkPackageLink' }
      }
    };

    scope.workPackage = workPackage;

    var callStub = sinon.stub(HookService, "call");
    var actions = [pluginActions.plugin_action_1, pluginActions.plugin_action_2];

    callStub.withArgs('workPackageDetailsMoreMenu').returns(actions);
    element = angular.element(html);
    compile();
  });


  var getLink = function(listRoot:any, action:any) {
    return listRoot.find('.' + action);
  };

  var shouldBehaveLikeListOfWorkPackageActionLinks = function(listRootSelector:any, actions:any) {
    var listRoot:any;

    beforeEach(function() {
      listRoot = angular.element(listRootSelector);
    });

    describe('links', function() {

      it('contains links for all core actions', function() {
        angular.forEach(actions, function(css, action) {
          var link = getLink(listRoot, action);

          expect(link.length).to.be.ok;
        });
      });

      it('contains links with correct description', function() {
        angular.forEach(actions, function(css, action) {
          var link = getLink(listRoot, action);

          expect(link.text()).to.match(new RegExp(I18n.t('js.button_' + action)));
        });
      });
    });
  };

  var shouldBehaveLikeCorrectWorkPackageActionLinkCss = function(listRootSelector:any, actions:any) {
    var listRoot:any;

    beforeEach(function() {
      listRoot = angular.element(listRootSelector);
    });

    describe('link css', function() {
      it('contains links with correct description', function() {
        angular.forEach(actions, function(css:any, action:any) {
          var link:any = getLink(listRoot, action);
          var pluginCss = pluginActions[action][action];

          angular.forEach(pluginCss, function(value) {
            expect(link.hasClass(value)).to.be.true;
          });
          expect(link.text()).to.match(new RegExp(I18n.t('js.button_' + action)));
        });
      });
    });
  };

  describe('Core actions', function() {
    var listRootSelector = 'ul.dropdown-menu';
    var actions = {
      log_time: 'icon-log_time',
      move: 'icon-move',
      delete: 'icon-delete'
    };

    shouldBehaveLikeListOfWorkPackageActionLinks(listRootSelector, actions);
  });

  describe('Plugin actions', function() {
    var listRootSelector = 'ul.dropdown-menu';
    var actions = {
      plugin_action_1: 'plugin_action_1_css_1',
      plugin_action_2: 'plugin_action_2_css_1'
    };

    shouldBehaveLikeListOfWorkPackageActionLinks(listRootSelector, actions);

    shouldBehaveLikeCorrectWorkPackageActionLinkCss(listRootSelector, actions);
  });
});
