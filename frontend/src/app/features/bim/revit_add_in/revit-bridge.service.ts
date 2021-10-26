// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { Injectable, Injector } from '@angular/core';
import { BehaviorSubject, Observable, Subject } from 'rxjs';
import {
  distinctUntilChanged, filter, first, map,
} from 'rxjs/operators';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ViewpointsService } from 'core-app/features/bim/bcf/helper/viewpoints.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { BcfViewpointData, CreateBcfViewpointData } from 'core-app/features/bim/bcf/api/bcf-api.model';

declare global {
  interface Window {
    RevitBridge:any;
  }
}

@Injectable()
export class RevitBridgeService extends ViewerBridgeService {
  public shouldShowViewer = false;

  public viewerVisible$ = new BehaviorSubject<boolean>(false);

  private revitMessageReceivedSource = new Subject<{ messageType:string, trackingId:string, messagePayload:any }>();

  private trackingIdNumber = 0;

  @InjectField() viewpointsService:ViewpointsService;

  revitMessageReceived$ = this.revitMessageReceivedSource.asObservable();

  constructor(readonly injector:Injector) {
    super(injector);

    if (window.RevitBridge) {
      this.hookUpRevitListener();
    } else {
      window.addEventListener('revit.plugin.ready', () => {
        this.hookUpRevitListener();
      }, { once: true });
    }
  }

  public viewerVisible() {
    return this.viewerVisible$.getValue();
  }

  public getViewpoint$():Observable<CreateBcfViewpointData> {
    const trackingId = this.newTrackingId();

    this.sendMessageToRevit('ViewpointGenerationRequest', trackingId, '');

    return this.revitMessageReceived$
      .pipe(
        distinctUntilChanged(),
        filter((message) => message.messageType === 'ViewpointData' && message.trackingId === trackingId),
        first(),
      )
      .pipe(
        map((message) => {
          const viewpointJson = message.messagePayload;

          viewpointJson.snapshot = {
            snapshot_type: 'png',
            snapshot_data: viewpointJson.snapshot,
          };

          return viewpointJson;
        }),
      );
  }

  public showViewpoint(workPackage:WorkPackageResource, index:number) {
    this.viewpointsService
      .getViewPoint$(workPackage, index)
      .subscribe((viewpoint:BcfViewpointData) =>
        this.sendMessageToRevit(
          'ShowViewpoint',
          this.newTrackingId(),
          JSON.stringify(viewpoint),
        )
      );
  }

  sendMessageToRevit(messageType:string, trackingId:string, messagePayload?:any) {
    if (!this.viewerVisible()) {
      return;
    }

    const jsonPayload = messagePayload != null ? JSON.stringify(messagePayload) : null;
    window.RevitBridge.sendMessageToRevit(messageType, trackingId, jsonPayload);
  }

  private hookUpRevitListener() {
    window.RevitBridge.sendMessageToOpenProject = (messageString:string) => {
      const message = JSON.parse(messageString);
      const { messageType } = message;
      const { trackingId } = message;
      const messagePayload = JSON.parse(message.messagePayload);

      this.revitMessageReceivedSource.next({
        messageType,
        trackingId,
        messagePayload,
      });
    };
    this.viewerVisible$.next(true);
  }

  newTrackingId():string {
    this.trackingIdNumber += 1;
    return String(this.trackingIdNumber);
  }
}
