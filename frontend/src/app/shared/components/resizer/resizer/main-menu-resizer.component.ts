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

import { ChangeDetectionStrategy, Component, computed, ElementRef, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { MainMenuToggleService } from 'core-app/core/main-menu/main-menu-toggle.service';
import { ResizeDelta } from 'core-app/shared/components/resizer/resizer.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { debounceTime, map } from 'rxjs/operators';

const RESIZE_EVENT = 'main-menu-resize';

@Component({
  selector: 'opce-main-menu-resizer',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <op-resizer class="main-menu--resizer"
                [customHandler]="true"
                cursorClass="col-resize"
                (resizeFinished)="resizeEnd()"
                (resizeStarted)="resizeStart()"
                (move)="resizeMove($event)">
      <button
        class="spot-link main-menu--navigation-toggler"
        [attr.aria-label]="ariaLabel()"
        [attr.aria-expanded]="isOpen()"
        [class.open]="isOpen()"
        (click)="toggleService.toggleNavigation($event)"
      >
        <span class="resize-handle"><svg op-resizer-vertical-lines-icon size="small"></svg></span>
        <span class="collapse-menu"><svg chevron-left-icon size="small"></svg></span>
        <span class="expand-menu"><svg chevron-right-icon size="small"></svg></span>
      </button>
    </op-resizer>
  `,
  standalone: false,
})
export class MainMenuResizerComponent extends UntilDestroyedMixin {
  readonly toggleService = inject(MainMenuToggleService);
  readonly I18n = inject(I18nService);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  private readonly elementWidth = signal<number>(0);
  private readonly mainMenu = document.querySelector('#main-menu')!;

  readonly isOpen = toSignal(
    this.toggleService.changeData$.pipe(
      debounceTime(50),
      map(() => this.toggleService.showNavigation)
    ),
    { initialValue: this.toggleService.showNavigation }
  );

  readonly isResizing = signal<boolean>(false);
  readonly ariaLabel = computed(() =>
    this.isResizing()
      ? this.text.menu_resize
      : this.isOpen()
        ? this.text.menu_collapse
        : this.text.menu_expand
  );

  readonly text = {
    menu_expand: this.I18n.t('js.label_expand_project_menu'),
    menu_collapse: this.I18n.t('js.label_hide_project_menu'),
    menu_resize: this.I18n.t('js.label_resize_project_menu')
  };

  public resizeStart() {
    this.elementWidth.set(this.mainMenu.clientWidth);
    this.isResizing.set(true);
  }

  public resizeMove(deltas:ResizeDelta) {
    this.toggleService.saveWidth(this.elementWidth() + deltas.absolute.x);
  }

  public resizeEnd() {
    this.isResizing.set(false);
    window.dispatchEvent(new Event(RESIZE_EVENT));
  }
}
