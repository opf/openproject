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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageQueryStateService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-base.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';

export const bcfCardsViewIdentifier = 'cards';
export const bcfViewerViewIdentifier = 'viewer';
export const bcfSplitViewTableIdentifier = 'splitTable';
export const bcfSplitViewCardsIdentifier = 'splitCards';
export const bcfTableViewIdentifier = 'table';

export type BcfViewState = 'cards'|'viewer'|'splitTable'|'splitCards'|'table';

const bcfViewStates:readonly unknown[] = [
  bcfCardsViewIdentifier,
  bcfViewerViewIdentifier,
  bcfSplitViewTableIdentifier,
  bcfSplitViewCardsIdentifier,
  bcfTableViewIdentifier,
] satisfies BcfViewState[];

export function isBcfViewState(value:unknown):value is BcfViewState {
  return bcfViewStates.includes(value);
}

@Injectable()
export class BcfViewService extends WorkPackageQueryStateService<BcfViewState> {
  private readonly I18n = inject(I18nService);
  private readonly viewerBridgeService = inject(ViewerBridgeService);

  public text:Record<string, string> = {
    cards: this.I18n.t('js.views.card'),
    viewer: this.I18n.t('js.ifc_models.views.viewer'),
    splitTable: this.I18n.t('js.ifc_models.views.split'),
    splitCards: this.I18n.t('js.ifc_models.views.split_cards'),
    table: this.I18n.t('js.views.list'),
  };

  public icon:Record<string, string> = {
    cards: 'icon-view-card',
    viewer: 'icon-view-model',
    splitTable: 'icon-view-split-viewer-table',
    splitCards: 'icon-view-split2',
    table: 'icon-view-list',
  };

  hasChanged(query:QueryResource):boolean {
    const saved = query.displayRepresentation;
    return this.current !== (isBcfViewState(saved) ? this.effectiveState(saved) : saved);
  }

  applyToQuery(query:QueryResource):boolean {
    if (this.hasChanged(query)) {
      query.displayRepresentation = this.current;
    }
    return true;
  }

  public valueFromQuery(query:QueryResource):BcfViewState|undefined {
    const saved = query.displayRepresentation;

    if (isBcfViewState(saved)) {
      return this.effectiveState(saved);
    }

    return this.viewerBridgeService.shouldShowViewer ? 'splitCards' : 'cards';
  }

  public update(value:BcfViewState):void {
    super.update(this.effectiveState(value));
  }

  public currentViewerState():BcfViewState|undefined {
    return this.current;
  }

  private effectiveState(state:BcfViewState):BcfViewState {
    if (this.viewerBridgeService.shouldShowViewer) {
      return state;
    }

    switch (state) {
      case 'viewer':
      case 'splitCards':
        return 'cards';
      case 'splitTable':
        return 'table';
      default:
        return state;
    }
  }
}
