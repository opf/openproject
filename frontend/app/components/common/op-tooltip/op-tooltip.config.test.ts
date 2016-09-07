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

import {openprojectModule} from '../../../angular-modules';

describe('opTooltip config', () => {
  var opTooltipService;
  var controller;

  var mouseOver;

  var tooltipDirective;
  var tooltipElement;

  var tooltipMock;

  beforeEach(angular.mock.module(openprojectModule.name));
  beforeEach(angular.mock.inject(function ($rootScope,
                                           $rootElement,
                                           $compile,
                                           _opTooltipService_) {
    opTooltipService = _opTooltipService_;
    opTooltipService.show = sinon.stub();
    opTooltipService.hide = sinon.stub();

    tooltipElement = angular.element('<div class="op-tooltip"><div></div></div>');
    tooltipDirective = $compile('<div op-tooltip><div></div></div>')($rootScope);

    controller = tooltipDirective.controller('opTooltip');

    tooltipMock = {};
    controller.create = sinon.stub().returns(tooltipMock);

    mouseOver = element => {
      const type = 'mouseover';
      const target = element.get(0);

      $rootElement.triggerHandler({target, type});
    };
  }));

  function testShowTooltip(prepare) {
    beforeEach(() => prepare());

    it('should create the tooltip', () => {
      expect(controller.create.calledOnce).to.be.true;
    });

    it('should show the tooltip', () => {
      expect(opTooltipService.show.calledWith(tooltipMock, controller.$element)).to.be.true;
    });
  }

  function testHideTooltip(prepare) {
    beforeEach(() => prepare());

    it('should hide the tooltip', () => {
      expect(opTooltipService.hide.calledOnce).to.be.true;
    });
  }

  function testKeepTooltipVisible(prepare) {
    beforeEach(() => prepare());

    it('should not hide the tooltip', () => {
      expect(opTooltipService.hide.called).to.be.false;
    });
  }

  function testTooltipDirectiveAndChildren(testFunc) {
    describe('when moving the mouse over the tooltip directive', () => {
      testFunc(() => {
        mouseOver(tooltipDirective);
      });
    });

    describe('when moving the mouse over a child element of the tooltip directive', () => {
      testFunc(() => {
        mouseOver(tooltipDirective.children());
      });
    });
  }

  describe('when the tooltip directive has a template', () => {
    beforeEach(() => {
      controller.hasTemplate = () => true;
    });

    testTooltipDirectiveAndChildren(testShowTooltip);
  });

  describe('when there is no tooltip template defined', () => {
    beforeEach(() => {
      controller.hasTemplate = () => false;
    });

    testTooltipDirectiveAndChildren(testHideTooltip);
  });

  describe('when moving the mouse over a tooltip', () => {
    testKeepTooltipVisible(() => {
      mouseOver(tooltipElement);
    });
  });

  describe('when moving the mouse over a child element of the tooltip', () => {
    testKeepTooltipVisible(() => {
      mouseOver(tooltipElement.children());
    });
  });

  describe('when moving the mouse over anything else', () => {
    testHideTooltip(() => {
      mouseOver(angular.element(document.body));
    });
  });
});
