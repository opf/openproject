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
  var mouseOver;
  var tooltip;
  var controller;

  beforeEach(angular.mock.module(openprojectModule.name));
  beforeEach(angular.mock.inject(function ($rootScope,
                                           $rootElement,
                                           $compile) {

    tooltip = $compile('<div op-tooltip><div></div></div>')($rootScope);
    controller = tooltip.controller('opTooltip');

    controller.show = sinon.stub();

    mouseOver = element => {
      const type = 'mouseover';
      const target = element.get(0);

      $rootElement.triggerHandler({target, type});
    };
  }));

  function testShowTooltip(prepare) {
    beforeEach(() => prepare());

    it('should show the tooltip', () => {
      expect(controller.show.calledOnce).to.be.true;
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

  describe('when moving the mouse over anything else', () => {
    var hide;

    beforeEach(angular.mock.inject($document => {
      hide = sinon.stub();
      $document.find = sinon.stub().withArgs('.op-tooltip').returns({hide});

      mouseOver(angular.element(document.body));
    }));

    it('should hide the tooltip', () => {
      expect(hide.calledOnce).to.be.true;
    });
  });
});
