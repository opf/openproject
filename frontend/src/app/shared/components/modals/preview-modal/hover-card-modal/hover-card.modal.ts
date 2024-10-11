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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  Input,
  OnInit,
  ViewChild,
} from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import {
  computePosition,
  flip,
  limitShift,
  Placement,
  shift,
} from '@floating-ui/dom';
import { WorkPackageIsolatedQuerySpaceDirective } from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

@Component({
  templateUrl: './hover-card.modal.html',
  styleUrls: ['./hover-card.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
})
export class HoverCardComponent extends OpModalComponent implements OnInit {
  @ViewChild('turboFrame')
  set turboFrame(frame:ElementRef<HTMLIFrameElement>|undefined) {
    if (frame !== undefined) {
      frame.nativeElement?.addEventListener('turbo:frame-load', () => {
        const modal = this.elementRef.nativeElement as HTMLElement;
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-explicit-any
        void this.reposition(modal, this.locals.event.target as HTMLElement);
      });
    }
  }

  turboFrameSrc:string;

  @Input() public alignment?:Placement = 'bottom-end';

  @Input() public allowRepositioning? = true;

  constructor(
    readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
    this.turboFrameSrc = this.locals.turboFrameSrc as string;
  }

  public async reposition(element:HTMLElement, target:HTMLElement) {
    const floatingEl = element.children[0] as HTMLElement;
    const { x, y } = await computePosition(
      target,
      floatingEl,
      {
        placement: this.alignment,
        middleware: this.allowRepositioning ? [
          flip({
            mainAxis: true,
            crossAxis: true,
            fallbackAxisSideDirection: 'start',
          }),
          shift({ limiter: limitShift() }),
        ] : [],
      },
    );
    Object.assign(floatingEl.style, {
      left: `${x}px`,
      top: `${y}px`,
    });
  }
}
