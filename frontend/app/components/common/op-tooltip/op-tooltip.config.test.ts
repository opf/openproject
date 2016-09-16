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
  var $timeout;

  var mouseOver;
  var tooltip;
  var controller;

  beforeEach(angular.mock.module(openprojectModule.name));
  beforeEach(angular.mock.inject(function ($rootScope,
                                           $rootElement,
                                           $compile,
                                           _$timeout_) {

    tooltip = $compile('<div op-tooltip><div></div></div>')($rootScope);
    controller = tooltip.controller('opTooltip');

    mouseOver = element => {
      const type = 'mouseover';
      const target = element.get(0);

      $rootElement.triggerHandler({target, type});
    };

    $timeout = _$timeout_;
    $timeout.cancel = sinon.stub();
  }));

  const containerVisible = () =>
    angular.element('#op-tooltip-container').hasClass('op-tooltip-visible');

  function testShowTooltip(prepare) {
    describe('when the tooltip directive has a tooltip service', () => {
      beforeEach(() => {
        controller.show = sinon.stub().returns(true);
        prepare();
        $timeout.flush();
      });

      it('should show the container', () => {
        expect(containerVisible()).to.be.true;
      });
    });

    describe('when the tooltip directive has no tooltip service', () => {
      beforeEach(() => {
        controller.show = sinon.stub().returns(false);
        prepare();
        $timeout.flush();
      });

      it('should keep the container invisible', () => {
        expect(containerVisible()).to.be.false;
      });
    });
  }

  describe('when moving the mouse over the tooltip directive', () => {
    testShowTooltip(() => {
      mouseOver(tooltip);
    });
  });

  describe('when moving the mouse over a child element of the tooltip directive', () => {
    testShowTooltip(() => {
      mouseOver(tooltip.children());
    });
  });

  describe('when moving the mouse over the tooltip itself', () => {
    var tooltipElement;

    beforeEach(() => {
      tooltipElement = angular.element('<div class="op-tooltip"></div>');
      mouseOver(tooltip);
      mouseOver(tooltipElement);
    });

    it('should cancel previous timeouts', () => {
      expect($timeout.cancel.called).to.be.true;
    });
  });

  describe('when moving the mouse over anything else', () => {
    beforeEach(() => {
      mouseOver(angular.element(document.body));
    });

    it('should hide the container', () => {
      expect(containerVisible()).to.be.false;
    });
  });
});
