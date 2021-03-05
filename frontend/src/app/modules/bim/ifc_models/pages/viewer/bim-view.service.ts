//-- copyright
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Injectable, OnDestroy } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { Observable } from "rxjs";
import { StateService, TransitionService } from "@uirouter/core";
import { input } from "reactivestates";
import { takeUntil } from "rxjs/operators";


export const bimListViewIdentifier = 'list';
export const bimTableViewIdentifier = 'table';
export const bimSplitViewCardsIdentifier = 'splitCards';
export const bimSplitViewListIdentifier = 'splitList';
export const bimViewerViewIdentifier = 'viewer';

export type BimViewState = 'list'|'viewer'|'splitList'|'splitCards'|'table';

@Injectable()
export class BimViewService implements OnDestroy {
  private _state = input<BimViewState>();

  public text:any = {
    list: this.I18n.t('js.views.card'),
    viewer: this.I18n.t('js.ifc_models.views.viewer'),
    splitList: this.I18n.t('js.ifc_models.views.split'),
    splitCards: this.I18n.t('js.ifc_models.views.split_cards'),
    table: this.I18n.t('js.views.list'),
  };

  public icon:any = {
    list: 'icon-view-card',
    viewer: 'icon-view-model',
    splitList: 'icon-view-split-viewer-table',
    splitCards: 'icon-view-split2',
    table: 'icon-view-list',
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

  get view$():Observable<BimViewState> {
    return this._state.values$();
  }

  public observeUntil(unsubscribe:Observable<any>) {
    return this.view$.pipe(takeUntil(unsubscribe));
  }

  get current():BimViewState {
    return this._state.getValueOr(bimSplitViewCardsIdentifier);
  }

  public currentViewerState():BimViewState {
    if (this.state.includes('bim.partitioned.list')) {
      return this.state.params?.cards ?
        bimListViewIdentifier :
        bimTableViewIdentifier;
    } else if (this.state.includes('bim.**.model')) {
      return bimViewerViewIdentifier;
    } else if (this.state.includes('bim.partitioned.show')) {
      return this.state.params?.cards || this.state.params?.cards == null ?
        bimListViewIdentifier :
        bimTableViewIdentifier;
    } else {
      return this.state.params?.cards || this.state.params?.cards == null ?
        bimSplitViewCardsIdentifier :
        bimSplitViewListIdentifier;
    }
  }

  private detectView() {
    this._state.putValue(this.currentViewerState());
  }

  ngOnDestroy() {
    this.transitionFn();
  }
}
