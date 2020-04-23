// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation,
  wpDisplayListRepresentation
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {combineLatest} from "rxjs";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";


@Component({
  template: `
    <button class="button"
            id="wp-view-toggle-button"
            wpViewDropdown>
      <op-icon icon-classes="button--icon icon-view-{{view}}"></op-icon>
      <span class="button--text"
            aria-hidden="true"
            [textContent]="text[view]">
        </span>
      <op-icon icon-classes="button--icon icon-small icon-pulldown"></op-icon>
    </button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-view-toggle-button',
})
export class WorkPackageViewToggleButton extends UntilDestroyedMixin implements OnInit {
  public view:string;

  public text:any = {
    card: this.I18n.t('js.views.card'),
    list: this.I18n.t('js.views.list'),
    timeline: this.I18n.t('js.views.timeline'),
  };

  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpDisplayRepresentationService:WorkPackageViewDisplayRepresentationService,
              readonly wpTableTimeline:WorkPackageViewTimelineService) {
    super();
  }

  ngOnInit() {
    let statesCombined = combineLatest([
      this.wpDisplayRepresentationService.live$(),
      this.wpTableTimeline.live$(),
    ]);

    statesCombined.pipe(
      this.untilDestroyed()
    ).subscribe(([display, timelines]) => {
      this.detectView(display, timelines.visible);
      this.cdRef.detectChanges();
    });
  }

  public detectView(display:string|null, timelineVisible:boolean) {
    if (display === wpDisplayCardRepresentation) {
      this.view = wpDisplayCardRepresentation;
      return;
    }

    if (timelineVisible) {
      this.view = 'timeline';
    } else {
      this.view = wpDisplayListRepresentation;
    }
  }
}
