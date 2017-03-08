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

import {opUiComponentsModule} from '../../../angular-modules';
import {opApiModule} from './../../../angular-modules';
import {debugLog} from '../../../helpers/debug_output';

function requestInterval(fn:Function, delay:number) {
	let start:number = new Date().getTime();
	let handle:any = {};
	function loop() {
		handle.value = window.requestAnimationFrame(loop);
		var current = new Date().getTime(),
		delta = current - start;
		if (delta >= delay) {
			fn();
			start = new Date().getTime();
		}
	}
	handle.value = window.requestAnimationFrame(loop);
	return handle;
};

export const opDimensionEventName = 'op:resize';

function detectDimensionChanges($window:ng.IWindowService) {
  return {
    restrict: 'A',
    link: function(scope:ng.IScope, element:ng.IAugmentedJQuery, attr:ng.IAttributes) {
      const el = element[0];

      let height = 0, width = 0;
      requestInterval(() => {

        let newHeight = el.offsetHeight;
        let newWidth = el.offsetWidth;

        if (newHeight !== height ||
            newWidth !== width) {

          debugLog('Dimension change detected on ', element);
          element.trigger(opDimensionEventName);

          height = newHeight;
          width = newWidth;
        }
      }, 1000);
    }
  };
}

opUiComponentsModule.directive('detectDimensionChanges', detectDimensionChanges);

