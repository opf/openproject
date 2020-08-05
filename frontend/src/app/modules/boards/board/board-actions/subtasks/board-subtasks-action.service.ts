import {Injectable} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {StatusResource} from "core-app/modules/hal/resources/status-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Observable} from "rxjs";
import {map} from "rxjs/operators";
import {ApiV3FilterBuilder, buildApiV3Filter, FalseValue} from "core-components/api/api-v3/api-v3-filter-builder";
import {SubtasksBoardHeaderComponent} from "core-app/modules/boards/board/board-actions/subtasks/subtasks-board-header.component";

@Injectable()
export class BoardSubtasksActionService extends BoardActionService {
  filterName = 'parent';

  public get localizedName() {
    return this.I18n.t('js.boards.board_type.action_type.subtasks');
  }

  public headerComponent() {
    return SubtasksBoardHeaderComponent;
  }

  public canMove(workPackage:WorkPackageResource):boolean {
    return !!workPackage.changeParent;
  }

  protected loadValues(matching?:string):Observable<HalResource[]> {
    let filters = new ApiV3FilterBuilder();
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
