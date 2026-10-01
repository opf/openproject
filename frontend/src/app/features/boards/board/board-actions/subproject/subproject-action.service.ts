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
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SubprojectBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/subproject/subproject-board-header.component';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class BoardSubprojectActionService extends CachedBoardActionService {
  filterName = 'onlySubproject';

  resourceName = 'subproject';

  text = this.I18n.t('js.boards.board_type.board_type_title.subproject');

  description = this.I18n.t('js.boards.board_type.action_text_subprojects');

  label = this.I18n.t('js.boards.add_list_modal.labels.subproject');

  icon = 'icon-projects';

  image = imagePath('board_creation_modal/subproject.svg');

  localizedName = this.I18n.t('js.work_packages.properties.subproject');

  headerComponent() {
    return SubprojectBoardHeaderComponent;
  }

  canMove(workPackage:WorkPackageResource):boolean {
    // We can only move the work package
    // if the `move` (move between projects) is allowed.
    return !!workPackage.move;
  }

  assignToWorkPackage(changeset:WorkPackageChangeset, query:QueryResource) {
    const href = this.getActionValueId(query, true);
    changeset.setValue('project', { href });
  }

  protected loadUncached():Observable<HalResource[]> {
    const currentProjectId = this.currentProject.id!;
    return this
      .apiV3Service
      .projects
      .filtered(
        new ApiV3FilterBuilder()
          .add('ancestor', '=', [currentProjectId])
          .add('active', '=', true),
      )
      .get()
      .pipe(
        map((collection) => collection.elements),
      );
  }
}
