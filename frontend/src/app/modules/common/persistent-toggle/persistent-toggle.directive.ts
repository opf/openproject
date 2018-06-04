persistent-toggle-directive-test.js//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {Directive, ElementRef, Input, OnInit} from "@angular/core";

@Directive({
  selector: 'persistent-toggle'
})
export class PersistentToggleDirective implements OnInit {
  @Input() public identifier:string;
  private isHidden:boolean;

  constructor(readonly elementRef:ElementRef) {
  }

  public ngOnInit() {
    const element = jQuery(this.elementRef.nativeElement);

    var clickHandler = element.find('.persistent-toggle--click-handler'),
      targetNotification = element.find('.persistent-toggle--notification');

    this.isHidden = (window as any).OpenProject.guardedLocalStorage(this.identifier) === 'true';

    // Clicking the handler toggles the notification
    clickHandler.bind('click', () => {
      this.toggle(!this.isHidden, targetNotification);
    });

    // Closing the notification remembers the decision
    targetNotification.find('.notification-box--close').bind('click', () => {
      this.toggle(true, targetNotification);
    });
2
    // Set initial state
    targetNotification.prop('hidden', !!this.isHidden);
  }

  private toggle(isNowHidden:boolean, targetNotification:JQuery) {
    (window as any).OpenProject.guardedLocalStorage(this.identifier, (!!isNowHidden).toString());
    this.isHidden = isNowHidden;

    if (isNowHidden) {
      targetNotification.slideUp(400, () => {
        // Set hidden only after animation completed
        targetNotification.prop('hidden', true);
      });
    } else {
      targetNotification.slideDown();
      targetNotification.prop('hidden', false);
    }
  }
}
