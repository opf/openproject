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

import { Injectable } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageQueryStateService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-base.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';

export const bcfCardsViewIdentifier = 'cards';
export const bcfViewerViewIdentifier = 'viewer';
export const bcfSplitViewTableIdentifier = 'splitTable';
export const bcfSplitViewCardsIdentifier = 'splitCards';
export const bcfTableViewIdentifier = 'table';

export type BcfViewState = 'cards'|'viewer'|'splitTable'|'splitCards'|'table';

@Injectable()
export class BcfViewService extends WorkPackageQueryStateService<BcfViewState> {
  public text:{ [key:string]:string } = {
    cards: this.I18n.t('js.views.card'),
    viewer: this.I18n.t('js.ifc_models.views.viewer'),
    splitTable: this.I18n.t('js.ifc_models.views.split'),
    splitCards: this.I18n.t('js.ifc_models.views.split_cards'),
    table: this.I18n.t('js.views.list'),
  };

  public icon:{ [key:string]:string } = {
    cards: 'icon-view-card',
    viewer: 'icon-view-model',
    splitTable: 'icon-view-split-viewer-table',
    splitCards: 'icon-view-split2',
    table: 'icon-view-list',
  };

  constructor(
    private readonly I18n:I18nService,
    private readonly viewerBridgeService:ViewerBridgeService,
    protected readonly querySpace:IsolatedQuerySpace,
  ) {
    super(querySpace);
  }

  hasChanged(query:QueryResource):boolean {
    return this.current !== query.displayRepresentation;
  }

  applyToQuery(query:QueryResource):boolean {
    // eslint-disable-next-line no-param-reassign
    query.displayRepresentation = this.current;
    return true;
  }

  public valueFromQuery(query:QueryResource):BcfViewState|undefined {
    const dr = query.displayRepresentation;

    switch (dr) {
      case 'splitCards':
      case 'splitTable':
      case 'cards':
      case 'table':
      case 'viewer':
        return dr;
      default:
        return this.viewerBridgeService.shouldShowViewer ? 'splitCards' : 'cards';
    }
  }

  public currentViewerState():BcfViewState|undefined {
    return this.current;
  }
}
