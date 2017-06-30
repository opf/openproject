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

import {wpDirectivesModule} from '../../../angular-modules';
import {scopedObservable} from '../../../helpers/angular-rx-utils';
import {BehaviorSubject} from 'rxjs';

// with courtesy of http://stackoverflow.com/a/29722694/3206935

function focusWithinDirective($timeout:ng.ITimeoutService) {
  return {
    restrict: 'A',

    scope: {
      selector: '=focusWithin'
    },

    link: (scope:ng.IScope, element:ng.IAugmentedJQuery) => {
      let focusedObservable = new BehaviorSubject(false);

      scopedObservable(
          scope,
          focusedObservable
        )
        .auditTime(50)
        .subscribe(focused => {
           element.toggleClass('-focus', focused);
        });


      let focusListener = function () {
          focusedObservable.next(true);
      };
      element[0].addEventListener('focus', focusListener, true);

      let blurListener = function () {
          focusedObservable.next(false);
      };
      element[0].addEventListener('blur', blurListener, true);

      $timeout(() => {
        element.addClass('focus-within--trigger');
        element.find(scope.selector).addClass('focus-within--depending');
      }, 0);
    }
  };
}

wpDirectivesModule.directive('focusWithin', focusWithinDirective);
