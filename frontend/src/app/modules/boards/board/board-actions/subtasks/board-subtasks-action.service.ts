import { Injectable } from "@angular/core";
import { BoardActionService } from "core-app/modules/boards/board/board-actions/board-action.service";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { SubtasksBoardHeaderComponent } from "core-app/modules/boards/board/board-actions/subtasks/subtasks-board-header.component";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { WorkPackageChangeset } from "core-components/wp-edit/work-package-changeset";
import { ImageHelpers } from "core-app/helpers/images/path-helper";

@Injectable()
export class BoardSubtasksActionService extends BoardActionService {
  filterName = 'parent';

  text = this.I18n.t('js.boards.board_type.board_type_title.subtasks');

  description = this.I18n.t('js.boards.board_type.action_text_subtasks');

  label = this.I18n.t('js.boards.add_list_modal.labels.subtasks');

  icon = 'icon-hierarchy';

  image = ImageHelpers.imagePath('board_creation_modal/parent-child.svg');

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
    filters.add('project', '=', [this.currentProject.id]);

    if (matching) {
      filters.add('subjectOrId', '**', [matching]);
    }

    return this
      .apiV3Service
      .work_packages
      .filtered(filters)
      .get()
      .pipe(
        map(collection => collection.elements)
      );
  }

  protected require(id:string):Promise<HalResource> {
    return this
      .apiV3Service
      .work_packages
      .id(id)
      .get()
      .toPromise();
  }
}
