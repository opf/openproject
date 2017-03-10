// -- copyright
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
// ++

import {WorkPackageNavigationButtonController} from './wp-buttons.module';

var expect = chai.expect;

class GenericWpButtonController extends WorkPackageNavigationButtonController {

  public accessKey:number = 1;
  public activeState:string = 'some-state.show';
  public buttonId:string = 'some-button-id';
  public iconClass:string = 'some-icon-class';

  constructor(public $state:ng.ui.IStateService, public I18n:op.I18n) {
    super($state, I18n);
  }

  public performAction() {
  }

  public get labelKey():string {
    return 'js.some-label';
  }

  public get textKey():string {
    return 'js.some-text';
  }

}

describe('WP button directives', () => {
  var $state:any, I18n:any, scope:any, label:any, button:any;
  var controller:GenericWpButtonController;

  before(() => {
    angular.module('openproject.wpButtons').directive('genericWpButton', function () {
      return {
        templateUrl: '/components/wp-buttons/wp-button.template.html',

        scope: {
          disabled: '=?'
        },

        controller: GenericWpButtonController,
        controllerAs: 'vm',
        bindToController: true
      }
    });
  });

  beforeEach(angular.mock.module('openproject.wpButtons', 'openproject.templates'));

  beforeEach(angular.mock.inject(($compile:ng.ICompileService, $rootScope:ng.IRootScopeService,
                                  _$state_:ng.ui.IStateService, _I18n_:any) => {

    var html = '<generic-wp-button disabled="disabled"></generic-wp-button>';

    $state = _$state_;
    I18n = _I18n_;

    scope = $rootScope.$new();
    var element = angular.element(html);

    var stub = sinon.stub(I18n, 't');
    stub.withArgs('js.some-label').returns('a wonderful title');
    stub.withArgs('js.some-text').returns('text');

    $compile(element)(scope);
    scope.$digest();

    controller = element.controller('genericWpButton');
    label = element.find('span');
    button = element.find('button');
  }));

  afterEach(() => {
    I18n.t.restore();
  });

  describe('when initial', () => {
    it('should have the performAction method', () => {
      expect(controller.performAction).not.to.throw(Error);
    });

    it('should be enabled by default', () => {
      expect(controller.disabled).not.to.be.ok;
    });

    it('should be disabled if disabled attribute is set', () => {
      scope.disabled = true;
      scope.$digest();
      expect(controller.disabled).to.be.true;
    });
  });

  describe('when activeState is set', () => {
    var includes:any;

    beforeEach(() => {
      includes = sinon.stub($state, 'includes');
    });

    it('should be active if the current state includes the given activeState name', () => {
      includes.withArgs(controller.activeState).returns(true);

      expect(controller.isActive()).to.be.true;
    });

    it('should not be active if the current state does not include the activeState name', () => {
      includes.returns(false);

      expect(controller.isActive()).to.be.false;
    });
  });

  describe('when active', () => {
    beforeEach(() => {
      sinon.stub(controller, 'isActive').returns(true);
      scope.$digest();
    });

    it('should not have a label with an access key', () => {
      expect(button.attr('accesskey')).not.to.eq(controller.activeAccessKey);
    });

    it("should have the button class set to '-active' ", () => {
      expect(button.attr('class')).to.contain('-active')
    });

    it('should have equal text values', () => {
      expect(button.attr('title').trim()).to.eq(controller.label);
    });
  });

  describe('when not active', () => {
    it('should have a label with an access key attribute', () => {
      expect(parseInt(button.attr('accesskey'))).to.eq(controller.activeAccessKey);
    });

    it("should have the 'activate' prefix in the text values", () => {
      expect(button.attr('title').trim()).to.contain(controller.label);
    });
  });
});
