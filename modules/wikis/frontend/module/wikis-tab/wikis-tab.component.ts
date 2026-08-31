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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit, ViewChild, inject } from '@angular/core';
import type { FrameElement } from '@hotwired/turbo';
import { filter } from 'rxjs/operators';

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TabComponent } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  selector: 'op-wikis-tab',
  templateUrl: './wikis-tab.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WikisTabComponent extends UntilDestroyedMixin implements OnInit, TabComponent {
  private elementRef = inject(ElementRef);
  private halEvents = inject(HalEventsService);
  readonly PathHelper = inject(PathHelperService);
  readonly I18n = inject(I18nService);

  @Input() public workPackage:WorkPackageResource;

  @ViewChild('frameElement') readonly frameElement:ElementRef<FrameElement>;

  turboFrameSrc:string;

  ngOnInit():void {
    this.turboFrameSrc = `${this.PathHelper.projectWorkPackagePath(this.workPackage.project.id as string, this.workPackage.id as string)}/wikis/tab`;
    this
      .halEvents
      .aggregated$('WorkPackage')
      .pipe(
        filter((events) => events.some((event) => event.eventType === 'updated'
          && event.id === this.workPackage.id
          && 'description' in (event.commit?.changes ?? {}))),
        this.untilDestroyed(),
      )
      .subscribe(() => {
        void this.frameElement?.nativeElement.reload();
      });
  }
}
