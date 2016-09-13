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

describe('opTooltip directive', () => {
  var tooltip: any = {};

  var scope;
  var element;
  var controller;

  var compile;

  beforeEach(angular.mock.module(openprojectModule.name, $provide => {
    $provide.value('someTooltip', tooltip);
  }));

  beforeEach(angular.mock.inject(function ($rootScope, $compile) {
    const html = '<div op-tooltip="tooltip"></div>';
    scope = $rootScope.$new();
    tooltip.show = sinon.stub();

    compile = () => {
      element = $compile(html)(scope);
      controller = element.controller('opTooltip');
    };
  }));

  describe('when the attribute value is the service name of an existing tooltip', () => {
    beforeEach(() => {
      scope.tooltip = 'someTooltip';
      compile();
    });

    it('should populate the tooltip attribute with that service', () => {
      expect(controller.tooltip).to.be.equal(tooltip);
    });

    describe('when calling show', () => {
      beforeEach(() => {
        controller.show();
      });

      it('should show the tooltip', () => {
        expect(tooltip.show.calledWith(controller.$element, scope)).to.be.true;
      });
    });
  });

  describe('when the attribute value is not a tooltip service name', () => {
    beforeEach(() => {
      scope.tooltip = 'nothing';
      compile();
    });

    it('should have a falsy tooltip attribute value', () => {
      expect(controller.tooltip).to.not.be.ok;
    });

    describe('when calling show', () => {
      beforeEach(() => {
        controller.show();
      });

      it('should do nothing', () => {
        expect(tooltip.show.called).to.be.false;
      });
    });
  });
});
