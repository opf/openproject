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

import {opModelsModule} from '../../../angular-modules';
import IDocumentService = angular.IDocumentService;
import {OpenProjectTooltipService} from './op-tooltip.service';

describe('opTooltipService', () => {
  var $document: IDocumentService;
  var opTooltipService: OpenProjectTooltipService;
  var isVisible;

  var clock;
  var wait;

  before(() => clock = sinon.useFakeTimers());
  after(() => clock.restore());

  beforeEach(angular.mock.module(opModelsModule.name));
  beforeEach(angular.mock.inject(function (_$document_, _opTooltipService_) {
    [$document, opTooltipService] = _.toArray(arguments);
    isVisible = () => opTooltipService.container.css('visibility') === 'visible';
    wait = () => clock.tick(opTooltipService.delay);
  }));

  it('should exist', () => {
    expect(opTooltipService).to.exist;
  });

  it('should be appended to the document body', () => {
    expect($document.find('#op-tooltip-container')).to.have.lengthOf(1);
  });

  it('should hide the container initially', () => {
    expect(isVisible()).to.be.false;
  });

  it('should have a container with z-index over 9000', () => {
    const over = power => expect(opTooltipService.container.css('z-index')).to.be.above(power);
    "it's" + over(9000);
  });

  describe('when calling the show method', () => {
    var tooltip;
    var target;

    beforeEach(() => {
      tooltip = angular.element('<div class="op-tooltip"></div>');

      target = angular.element('<div></div>').appendTo(document.body);
      target.css({
        width: 10,
        height: 10,
        padding: 5
      });

      opTooltipService.container.append('<div class="op-tooltip"></div>');

      opTooltipService.show(tooltip, target);
    });

    it('should make the tooltip appear above the original element', () => {
      const top = target.offset().top - tooltip.outerHeight();
      expect(parseInt(tooltip.css('top'))).to.equal(Math.floor(top));
    });

    it('should align the tooltip on the right of the original element', () => {
      const left = target.offset().left + target.outerWidth();
      expect(parseInt(tooltip.css('left'))).to.equal(parseInt(left));
    });

    it('should remove other tooltips', () => {
      expect(opTooltipService.container.find('.op-tooltip')).to.have.lengthOf(1);
    });

    it('should keep the container invisible initially', () => {
      expect(isVisible()).to.be.false;
    });

    it('should show the container after the delay time', () => {
      wait();
      expect(isVisible()).to.be.true;
    });

    describe('when calling hide afterwards', () => {
      beforeEach(() => {
        wait();
        opTooltipService.hide();
      });

      it('should keep the element visible for a while', () => {
        expect(isVisible()).to.be.true;
      });

      it('should hide the element after the delay time', () => {
        wait();
        expect(isVisible()).to.be.false;
      });
    });
  });
});
