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

import {ChangeDetectionStrategy, ChangeDetectorRef, Component, Injectable, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation,
  wpDisplayListRepresentation, wpDisplayRepresentation
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {combineLatest, Observable} from "rxjs";
import {StateService, TransitionService} from "@uirouter/core";
import {input} from "reactivestates";
import {OpenprojectIFCModelsModule} from "core-app/modules/ifc_models/openproject-ifc-models.module";


export const bimListViewIdentifier = 'list';
export const bimViewerViewIdentifier = 'viewer';
export const bimSplitViewIdentifier = 'split';

export type BimViewState = 'list'|'viewer'|'split';

@Injectable({ providedIn: OpenprojectIFCModelsModule })
export class BimViewService implements OnDestroy {
  public view = input<BimViewState>();

  public text:any = {
    list: this.I18n.t('js.ifc_models.views.list'),
    viewer: this.I18n.t('js.ifc_models.views.viewer'),
    split: this.I18n.t('js.ifc_models.views.split')
  };

  private transitionFn:Function;

  constructor(readonly I18n:I18nService,
              readonly transitions:TransitionService,
              readonly state:StateService) {

    this.detectView();

    this.transitionFn = this.transitions.onSuccess({}, (transition) => {
      this.detectView();
    });
  }

  get current():BimViewState {
    return this.view.getValueOr(bimSplitViewIdentifier);
  }

  private detectView() {
    if (this.state.current.name === 'bim.space.list') {
      this.view.putValue(bimListViewIdentifier);
    } else if (this.state.includes('bim.**.model')) {
      this.view.putValue(bimViewerViewIdentifier);
    } else {
      this.view.putValue(bimSplitViewIdentifier);
    }
  }

  ngOnDestroy() {
    this.transitionFn();
  }
}
