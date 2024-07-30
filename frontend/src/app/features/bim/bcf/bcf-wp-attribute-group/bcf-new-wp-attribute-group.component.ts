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

import { AfterViewInit, ChangeDetectionStrategy, Component } from '@angular/core';
import { BcfWpAttributeGroupComponent } from 'core-app/features/bim/bcf/bcf-wp-attribute-group/bcf-wp-attribute-group.component';
import { switchMap, take } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { forkJoin } from 'rxjs';
import { BcfViewpointItem } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint-item.interface';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

@Component({
  templateUrl: './bcf-wp-attribute-group.component.html',
  styleUrls: ['./bcf-wp-attribute-group.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BcfNewWpAttributeGroupComponent extends BcfWpAttributeGroupComponent implements AfterViewInit {
  galleryViewpoints:BcfViewpointItem[] = [];

  ngAfterViewInit():void {
    if (this.viewerVisible) {
      super.ngAfterViewInit();

      // Save any leftover viewpoints when saving the work package
      if (isNewResource(this.workPackage)) {
        this.observeCreation();
      }
    }
  }

  // Because this is a new WorkPackage, in order to save the
  // viewpoints on it we need to:
  // - Wait until the WorkPackage is created
  // - Create the BCFTopic on it to save the viewpoints
  private observeCreation() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        this.untilDestroyed(),
        take(1),
        switchMap((wp:WorkPackageResource) => this.viewpointsService.setBcfTopic$(wp), (wp) => wp),
        switchMap((wp:WorkPackageResource) => {
          this.workPackage = wp;
          const observables = this.galleryViewpoints
            .filter((viewPointItem) => !viewPointItem.href && viewPointItem.viewpoint)
            .map((viewPointItem) => this.viewpointsService.saveViewpoint$(this.workPackage, viewPointItem.viewpoint));

          return forkJoin(observables);
        }),
      )
      .subscribe(() => {
        this.viewpointsService.resetBcfTopic();
        this.showIndex = this.galleryViewpoints.length - 1;
      });
  }

  // Disable show viewpoint functionality
  showViewpoint(_workPackage:WorkPackageResource, _index:number):void {

  }

  deleteViewpoint(workPackage:WorkPackageResource, index:number):void {
    this.galleryViewpoints = this.galleryViewpoints.filter((_, i) => i !== index);

    this.setViewpointsOnGallery(this.galleryViewpoints);
  }

  saveViewpoint():void {
    this.viewerBridge
      .getViewpoint$()
      .subscribe((viewpoint) => {
        const newViewpoint = {
          snapshotURL: viewpoint.snapshot.snapshot_data,
          viewpoint,
        };

        this.galleryViewpoints = [
          ...this.galleryViewpoints,
          newViewpoint,
        ];

        this.setViewpointsOnGallery(this.galleryViewpoints);

        // Select the last created viewpoint and show it
        this.showIndex = this.galleryViewpoints.length - 1;
        this.selectViewpointInGallery();
      });
  }

  shouldShowGroup():boolean {
    return this.createAllowed && this.viewerVisible;
  }

  protected actions():{ icon:string, onClick:(evt:unknown, index:number) => void, titleText:string }[] {
    // Show only delete button
    return super
      .actions()
      .filter((el) => el.icon === 'icon-delete');
  }
}
