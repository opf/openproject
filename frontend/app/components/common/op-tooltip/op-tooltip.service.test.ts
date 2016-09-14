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
import IDocumentService = angular.IDocumentService;

describe('opTooltip service', () => {
  var $document: IDocumentService;
  var container;
  var opTooltip;

  beforeEach(angular.mock.module(openprojectModule.name, $provide => {
    $provide.factory('existingTooltip', opTooltip => opTooltip({}));
  }));

  beforeEach(angular.mock.inject(function (_$document_, _opTooltip_) {
    [$document, opTooltip] = _.toArray(arguments);
    container = $document.find('#op-tooltip-container');
  }));

  it('should exist', () => {
    expect(opTooltip).to.exist;
  });

  it('should append only one container to the document', () => {
    expect(container).to.have.lengthOf(1);
  });

  describe('when using get()', () => {
    function testGetMethod(name, expectation) {
      var tooltip;

      beforeEach(() => {
        tooltip = opTooltip.get(name);
      });

      it('should return that service', () => {
        expect(tooltip).to.be[expectation];
      });
    }

    describe('when using it for an existing tooltip service', () => {
      testGetMethod('existingTooltip', 'ok');
    });

    describe('when using it for a non existing service', () => {
      testGetMethod('something outta space', null);
    });

    describe('when using it for a service that is not a tooltip', () => {
      testGetMethod('opTooltip', null);
    });
  });

  describe('when creating a tooltip service', () => {
    var tooltip;
    var tooltipElement;
    var templateUrl = 'random';
    var scope;

    var targetElement;
    var targetScope;

    var show;

    beforeEach(angular.mock.inject(($rootScope, $templateCache) => {
      $templateCache.put(templateUrl, 'random content');

      targetElement = angular.element('body');
      targetScope = $rootScope.$new();

      scope = targetScope.$new();
      scope.$destroy = sinon.stub();
      targetScope.$new = sinon.stub().returns(scope);

      tooltip = opTooltip({templateUrl});
      show = () => tooltipElement = tooltip.show(targetElement, targetScope);
    }));

    describe('when using show', () => {
      beforeEach(() => show());

      it('should add a single tooltip to the dom', () => {
        expect(targetElement.find('.op-tooltip')).to.have.lengthOf(1);
      });

      it('should show the tooltip element', () => {
        expect(tooltipElement.is(':visible')).to.be.true;
      });

      it('should compile the contents of the tooltip', () => {
        expect(tooltipElement.html()).to.contain('random content');
      });

      describe('when using show again', () => {
        beforeEach(() => show());

        it('should still only have one tooltip', () => {
          expect(targetElement.find('.op-tooltip')).to.have.lengthOf(1);
        });
      });

      describe('when removing the tooltip element from the dom', () => {
        beforeEach(() => {
          tooltipElement.remove();
        });

        it('should destroy its scope', () => {
          expect(scope.$destroy.calledOnce).to.be.true;
        });
      });
    });

    describe('when no controller is defined', () => {
      beforeEach(() => {
        tooltip = opTooltip({templateUrl});
        show();
      });

      it('should add an empty controller to the scope', () => {
        expect(scope.opTooltipController).to.equal(angular.noop);
      });
    });

    describe('when a controller is defined', () => {
      const controller = class RandomCtrl {
      };

      beforeEach(() => {
        tooltip = opTooltip({controller, templateUrl});
        show();
      });

      it('should add the controller to the scope', () => {
        expect(scope.opTooltipController).to.equal(controller);
      });
    });
  });
});
