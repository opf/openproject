import { Injectable } from '@angular/core';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  firstValueFrom,
  Observable,
} from 'rxjs';
import { map } from 'rxjs/operators';
import { SubtasksBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/subtasks/subtasks-board-header.component';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Injectable()
export class BoardSubtasksActionService extends BoardActionService {
  filterName = 'parent';

  resourceName = 'parent-child';

  text = this.I18n.t('js.boards.board_type.board_type_title.subtasks');

  description = this.I18n.t('js.boards.board_type.action_text_subtasks');

  label = this.I18n.t('js.boards.add_list_modal.labels.subtasks');

  icon = 'icon-hierarchy';

  image = imagePath('board_creation_modal/parent-child.svg');

  localizedName = this.I18n.t('js.boards.board_type.action_type.subtasks');

  public headerComponent() {
    return SubtasksBoardHeaderComponent;
  }

  public canMove(workPackage:WorkPackageResource):boolean {
    return !!workPackage.changeParent;
  }

  assignToWorkPackage(changeset:WorkPackageChangeset, query:QueryResource) {
    const parentId = this.getActionValueId(query)?.toString();

    // Disable dragging a work package into its own column
    if (parentId === changeset.id) {
      throw new Error(this.I18n.t('js.boards.error_cannot_move_into_self'));
    }

    super.assignToWorkPackage(changeset, query);
  }

  protected loadValues(matching?:string):Observable<HalResource[]> {
    const filters = new ApiV3FilterBuilder();
    filters.add('is_milestone', '=', false);
    filters.add('project', '=', [this.currentProject.id || '']);

    if (matching) {
      filters.add('subjectOrId', '**', [matching]);
    }

    return this
      .apiV3Service
      .work_packages
      .filtered(filters, { pageSize: '-1' })
      .get()
      .pipe(
        map((collection) => collection.elements),
      );
  }

  protected require(id:string):Promise<HalResource> {
    return firstValueFrom(this.apiV3Service.work_packages.id(id).get());
  }
}
