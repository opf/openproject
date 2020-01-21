// -- copyright
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
// ++

import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {BcfPathHelperService} from "core-app/modules/bcf/helper/bcf-path-helper.service";
import {RevitBridgeService} from "core-app/modules/bcf/services/revit-bridge.service";
import {HttpClient, HttpHeaders} from "@angular/common/http";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {distinctUntilChanged, filter} from "rxjs/operators";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";

@Component({
  template: `
    <a [title]="text.add_viewpoint" class="button" (click)="handleClick()">
      <op-icon icon-classes="button--icon icon-add"></op-icon>
      <span class="button--text"> {{text.viewpoint}} </span>
    </a>
  `,
  selector: 'bcf-add-viewpoint-button',
})
export class BcfAddViewpointButtonComponent implements OnInit, OnDestroy {
  @Input() public workPackage:WorkPackageResource;

  public text = {
    viewpoint: this.I18n.t('js.bcf.viewpoint'),
    add_viewpoint: this.I18n.t('js.bcf.add_viewpoint'),
  };

  constructor(readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly revitBridgeService:RevitBridgeService,
              readonly httpClient:HttpClient) {
  }

  public handleClick() {
    console.log("handleClick");
    const trackingId = this.revitBridgeService.newTrackingId();

    this.revitBridgeService.sendMessageToRevit('ViewpointGenerationRequest', trackingId, '');

    this.revitBridgeService.revitMessageReceived$
      .pipe(
        distinctUntilChanged(),
        filter(message => message.messageType === 'ViewpointData' && message.trackingId === trackingId),
        untilComponentDestroyed(this)
      )
      .subscribe(message => this.saveViewpoint(message));
  }

  private saveViewpoint(message:any):void {
    console.log('save viewpoint with', message);
    var viewpointJson = message["messagePayload"];

    viewpointJson.snapshot = {
	    snapshot_type: 'png',
      snapshot_data: viewpointJson.snapshot
    };

    const headers = new HttpHeaders()
      .set("Content-Type", "application/json");
    this.httpClient
      .post(
        `/api/bcf/2.1/projects/${this.projectIdentifier()}/topics/${this.topicUuid()}/viewpoints`,
        viewpointJson,
        {
          headers: headers,
          withCredentials: true,
          responseType: 'json'
        }
      ).subscribe((data) => {
        console.log("Response of posting viewpiont", data);
      });
  }


  public ngOnInit():void {
    console.log("init add viewpoint button component");
  }

  public ngOnDestroy():void {
    // nop
  }

  private projectIdentifier():string|null {
    return this.currentProject.identifier;
  }

  private topicUuid():string {
    return this.workPackage.bcf.uuid;
  }
}
