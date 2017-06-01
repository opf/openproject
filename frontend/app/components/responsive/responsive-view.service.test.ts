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

import {ResponsiveView} from './responsive-view.service';

var expect = chai.expect;

describe('responsiveView service', () => {
  describe('isSmall method', () => {
    var responsiveView:any;
    var $window = {
      innerWidth: 0
    };

    beforeEach(() => {
      angular.mock.module('openproject.responsive', ($provide:any) => {
        $provide.value('$window', $window);
      });

      angular.mock.inject((_responsiveView_: ResponsiveView) => {
        responsiveView = _responsiveView_;
        $window.innerWidth = responsiveView.small;
      });
    });

    it('should return true if the window size is less than the "small" value', () => {
      $window.innerWidth -= 10;
      expect(responsiveView.isSmall()).to.be.true;
    });

    it('should return false if the window width is greater than the "small" value', () => {
      $window.innerWidth += 10;
      expect(responsiveView.isSmall()).to.be.false;
    })
  });

  describe('onResize method', () => {
    var responsiveView:any, $window:any;

    beforeEach(() => {
      angular.mock.module('openproject.responsive');

      angular.mock.inject((_responsiveView_:ResponsiveView, _$window_:ng.IWindowService) => {
        responsiveView = _responsiveView_;
        $window = _$window_;
      });
    });

    it('should execute the given callback', () => {
      var callback = sinon.stub();

      responsiveView.onResize(callback);
      angular.element($window).trigger('resize');

      expect(callback.calledOnce).to.be.true;
    });
  });
});
