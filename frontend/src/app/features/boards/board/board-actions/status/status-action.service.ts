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

import { Injectable } from '@angular/core';
import { Board } from 'core-app/features/boards/board/board';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { StatusBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/status/status-board-header.component';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';

@Injectable()
export class BoardStatusActionService extends CachedBoardActionService {
  filterName = 'status';

  resourceName = 'status';

  text = this.I18n.t('js.boards.board_type.board_type_title.status');

  description = this.I18n.t('js.boards.board_type.action_text_status');

  label = this.I18n.t('js.boards.add_list_modal.labels.status');

  icon = 'icon-workflow';

  image = imagePath('board_creation_modal/status.svg');

  localizedName = this.I18n.t('js.work_packages.properties.status');

  headerComponent() {
    return StatusBoardHeaderComponent;
  }

  public warningTextWhenNoOptionsAvailable():Promise<string> {
    return Promise.resolve(this.I18n.t('js.boards.add_list_modal.warning.status'));
  }

  protected loadUncached():Observable<StatusResource[]> {
    return this
      .apiV3Service
      .statuses
      .get()
      .pipe(
        map((collection) => collection.elements),
      );
  }
}
