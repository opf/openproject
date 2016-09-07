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
  var opTooltipService;
  var element;
  var controller;

  beforeEach(angular.mock.module(openprojectModule.name));
  beforeEach(angular.mock.inject(function ($rootScope,
                                           $compile,
                                           $templateCache,
                                           _opTooltipService_) {
    opTooltipService = _opTooltipService_;
    opTooltipService.show = sinon.stub();

    const html = '<div op-tooltip="templateUrl"></div>';
    const scope: any = $rootScope.$new();

    scope.templateUrl = 'recipe';
    scope.templateValue = 'the cake is a lie';

    $templateCache.put('recipe', '{{ templateValue }}');

    element = $compile(html)(scope);
    element.css({
      width: 10,
      height: 10,
      padding: 5
    });
    controller = element.controller('opTooltip');
  }));

  describe('when calling the show method of the tooltip controller', () => {
    var tooltip;

    beforeEach(() => {
      tooltip = controller.show();
    });

    it('should compile the content of the tooltip', () => {
      expect(tooltip.html()).to.contain('the cake is a lie');
    });

    it('should pass the tooltip to the show method of the tooltip service', () => {
      expect(opTooltipService.show.calledWith(tooltip)).to.be.true;
    });

    it('should make the tooltip appear below the original element', () => {
      const top = element.offset().top + element.outerHeight();
      expect(parseInt(tooltip.css('top'))).to.equal(top);
    });

    it('should align the tooltip on the right of the original element', () => {
      const left = element.offset().left + element.outerWidth();
      expect(parseInt(tooltip.css('left'))).to.equal(left);
    });
  });
});
