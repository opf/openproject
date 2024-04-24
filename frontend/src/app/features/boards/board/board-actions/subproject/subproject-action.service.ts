import { Injectable } from '@angular/core';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SubprojectBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/subproject/subproject-board-header.component';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
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
        map((collection:CollectionResource<UserResource>) => collection.elements),
      );
  }
}
