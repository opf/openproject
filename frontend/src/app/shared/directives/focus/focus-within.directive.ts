//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { BehaviorSubject } from 'rxjs';
import { auditTime } from 'rxjs/operators';
import { Directive, ElementRef, Input, OnInit, inject } from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

// with courtesy of http://stackoverflow.com/a/29722694/3206935

@Directive({
  selector: '[opFocusWithin]',
  standalone: false,
})
export class FocusWithinDirective extends UntilDestroyedMixin implements OnInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  @Input() public selector:string;

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    const focusedObservable = new BehaviorSubject(false);

    focusedObservable
      .pipe(
        this.untilDestroyed(),
        auditTime(50),
      )
      .subscribe((focused) => {
        element.classList.toggle('-focus', focused);
      });

    const focusListener = function () {
      focusedObservable.next(true);
    };
    element.addEventListener('focus', focusListener, true);

    const blurListener = function () {
      focusedObservable.next(false);
    };
    element.addEventListener('blur', blurListener, true);

    setTimeout(() => {
      element.classList.add('op-focus-within');
      element.querySelector(this.selector)?.classList.add('op-focus-within');
    }, 0);
  }
}
