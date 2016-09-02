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
import {Tooltip} from './op-tooltip.service';
import IRootElementService = angular.IRootElementService;

describe('opTooltip directive', () => {
  var mouseOver;
  var controller;
  var element;

  beforeEach(angular.mock.module(openprojectModule.name));
  beforeEach(angular.mock.inject(function ($rootScope, $rootElement, $compile) {
    const html = '<div op-tooltip></div>';
    element = $compile(html)($rootScope);
    controller = element.controller('opTooltip');

    mouseOver = target => {
      const type = 'mouseover';
      $rootElement.triggerHandler({target, type});
    };
  }));

  it('should be empty', () => {
    expect(element.html()).to.be.empty;
  });

  it('should have a tooltip attribute that is a Tooltip', () => {
    expect(controller.tooltip).to.be.an.instanceOf(Tooltip);
  });

  describe('when moving the mouse over the directive', () => {
    beforeEach(() => {
      controller.show = sinon.stub();
      mouseOver(element.get(0));
    });

    it('should call the show method of the controller', () => {
      expect(controller.show.calledOnce).to.be.true;
    });

    describe('when moving the mouse over something else afterwards', () => {
      beforeEach(() => {
        mouseOver(document.body);
      });
    });
  });

  describe('when calling the show method of the controller', () => {
    beforeEach(() => {
      controller.tooltip.show = sinon.stub();
      controller.show();
    });

    it('should call the show method of the tooltip', () => {
      expect(controller.tooltip.show.calledOnce).to.be.true;
    });
  });
});
