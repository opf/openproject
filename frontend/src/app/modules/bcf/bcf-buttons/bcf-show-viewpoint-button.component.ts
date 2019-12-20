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

import {Component, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {BcfPathHelperService} from "core-app/modules/bcf/helper/bcf-path-helper.service";
import {RevitBridgeService} from "core-app/modules/bcf/services/revit-bridge.service";
import {distinctUntilChanged, filter} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";

@Component({
  template: `
    <a [title]="text.show_viewpoint" class="button" (click)="handleClick()">
      <op-icon icon-classes="button--icon icon-eye"></op-icon>
      <span class="button--text"> {{text.show_viewpoint}} </span>
    </a>
  `,
  selector: 'bcf-show-viewpoint-button',
})
export class BcfShowViewpointButtonComponent implements OnInit, OnDestroy {
  public text = {
    show_viewpoint: this.I18n.t('js.bcf.show_viewpoint'),
  };

  constructor(readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly bcfPathHelper:BcfPathHelperService,
              readonly revitBridgeService:RevitBridgeService) {
  }

  public handleClick() {
    console.log("handleClick");
    const trackingId = this.revitBridgeService.newTrackingId();

    this.revitBridgeService.sendMessageToRevit('ShowViewpoint', trackingId, JSON.stringify(this.tmpViewpoint));
  }

  private tmpViewpoint = {
      "perspective_camera": {
          "camera_view_point": {"x": -2.36, "y": 18.96, "z": -26.12},
          "camera_direction": {"x": 0.55, "y": -0.54, "z": 0.62},
          "camera_up_vector": {"x": 0.36, "y": 0.82, "z": 0.40},
          "field_of_view": 60
      },
      "orthogonal_camera": {
          "camera_view_point": {"x": -2.36, "y": 18.96, "z": -26.12},
          "camera_direction": {"x": 0.55, "y": -0.54, "z": 0.62},
          "camera_up_vector": {"x": 0.36, "y": 0.82, "z": 0.40},
          "view_to_world_scale": 1
      },
      "lines": [],
      "bitmaps": [],
      "clipping_planes": [
          {
              "location": {"x": 0, "y": 0, "z": 0},
              "direction": {"x": 0.5, "y": 0, "z": 0.5}
          }
      ],
      "components": {
          "visibility": {
              "view_setup_hints": {
                  "spaces_visible": false,
                  "space_boundaries_visible": false,
                  "openings_visible": false
              },
              "exceptions": [],
              "default_visibility": true
          },
          "selection": [
              {
                  "ifc_guid": "3b2U496P5Ebhz5FROhTwFH",
                  "originating_system": "xeokit",
                  "authoring_tool_id": "xeokit"
              },
              {
                  "ifc_guid": "2MGtJUm9nD$Re1_MDIv0g2",
                  "originating_system": "xeokit",
                  "authoring_tool_id": "xeokit"
              },
              {
                  "ifc_guid": "3IbuwYOm5EV9Q6cXmwVWqd",
                  "originating_system": "xeokit",
                  "authoring_tool_id": "xeokit"
              },
              {
                  "ifc_guid": "3lhisrBxL8xgLCRdxNG$2v",
                  "originating_system": "xeokit",
                  "authoring_tool_id": "xeokit"
              },
              {
                  "ifc_guid": "1uDn0xT8LBkP15zQc9MVDW",
                  "originating_system": "xeokit",
                  "authoring_tool_id": "xeokit"
              }
          ]
      },
      "snapshot": {
          "snapshot_type": "png",
          "snapshot_data": "data:image/png;base64,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"
      }
  };

  public ngOnInit():void {
    console.log("init show viewpoint button component");
  }

  public ngOnDestroy():void {
    // nop
  }
}
