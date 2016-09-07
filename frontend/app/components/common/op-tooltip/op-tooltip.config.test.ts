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

  var createTooltip;
  var mouseOver;
  var tooltip;

  beforeEach(angular.mock.module(openprojectModule.name, $provide => {
    opTooltipService = {hide: sinon.stub()};
    $provide.value('opTooltipService', opTooltipService);
  }));

  beforeEach(angular.mock.inject(function ($rootScope, $rootElement, $compile) {
    createTooltip = html => {
      tooltip = $compile(html)($rootScope).appendTo($rootElement);
      controller = tooltip.controller('opTooltip');
      controller.show = sinon.stub();
    };
    mouseOver = element => {
      const type = 'mouseover';
      const target = element.get(0);

      $rootElement.triggerHandler({target, type});
    };
  }));

  describe('when moving the mouse over a tooltip directive', () => {
    beforeEach(() => {
      createTooltip('<div op-tooltip></div>');
      mouseOver(tooltip);
    });

    it('should show the tooltip', () => {
      expect(controller.show.calledOnce).to.be.true;
    });
  });

  describe('when moving the mouse over a child element of a tooltip directive', () => {
    beforeEach(() => {
      createTooltip('<div op-tooltip><div class="child"></div></div>');
      mouseOver(tooltip.find('.child'));
    });

    it('should show the tooltip', () => {
      expect(controller.show.calledOnce).to.be.true;
    });
  });

  describe('when moving the mouse over a tooltip', () => {
    beforeEach(() => {
      mouseOver(angular.element('<div class="op-tooltip"></div>'));
    });

    it('should not hide the tooltip', () => {
      expect(opTooltipService.hide.called).to.be.false;
    });
  });

  describe('when moving the mouse over a child element of the tooltip', () => {
    beforeEach(() => {
      const element = angular.element('<div class="op-tooltip"><div class="child"></div></div>');
      mouseOver(element.find('.child'));
    });

    it('should not hide the tooltip', () => {
      expect(opTooltipService.hide.called).to.be.false;
    });
  });

  describe('when moving the mouse over anything else', () => {
    beforeEach(() => {
      mouseOver(angular.element(document.body));
    });

    it('should hide the tooltip', () => {
      expect(opTooltipService.hide.calledOnce).to.be.true;
    });
  });
});
