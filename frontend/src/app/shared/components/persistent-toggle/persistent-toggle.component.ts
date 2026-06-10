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

import { ChangeDetectionStrategy, Component, ElementRef, OnInit, inject } from '@angular/core';
import { slideDown, slideUp } from 'es6-slide-up-down';


@Component({
  selector: 'opce-persistent-toggle',
  template: '',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class PersistentToggleComponent implements OnInit {
  private elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  /** Unique identifier of the toggle */
  private identifier:string;

  /** Is hidden */
  private isHidden = false;

  /** Element reference */
  private element:HTMLElement;

  private targetNotification:HTMLElement|null;

  ngOnInit():void {
    this.element = this.elementRef.nativeElement;
    this.targetNotification = this.getTargetNotification();

    this.identifier = this.element.dataset.identifier!;
    this.isHidden = window.OpenProject.guardedLocalStorage(this.identifier) === 'true';

    // Set initial state
    if (this.targetNotification) {
      this.targetNotification.hidden = !!this.isHidden;

      // Register click handler
      this.element
        .parentElement
        ?.querySelector('.persistent-toggle--click-handler')
        ?.addEventListener('click', () => this.toggle(!this.isHidden));

      // Register target toaster close icon
      this.targetNotification
        .querySelector('.op-toast--close')
        ?.addEventListener('click', () => this.toggle(true));
    }
  }

  private getTargetNotification() {
    return this.element
      .parentElement!
      .querySelector<HTMLElement>('.persistent-toggle--toaster');
  }

  private toggle(isNowHidden:boolean) {
    this.isHidden = isNowHidden;
    window.OpenProject.guardedLocalStorage(this.identifier, (!!isNowHidden).toString());

    const targetNotification = this.targetNotification;
    if (!targetNotification) return;

    if (isNowHidden) {
      slideUp(targetNotification, 400);
      setTimeout(() => { targetNotification.hidden = true; }, 400);
    } else {
      targetNotification.hidden = false;
      slideDown(targetNotification, 400);
    }
  }
}
