import { Injectable } from '@angular/core';
import {
  AssigneeBoardHeaderComponent,
} from 'core-app/features/boards/board/board-actions/assignee/assignee-board-header.component';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { Board } from 'core-app/features/boards/board/board';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class BoardAssigneeActionService extends CachedBoardActionService {
  filterName = 'assignee';

  resourceName = 'assignee';

  text = this.I18n.t('js.boards.board_type.board_type_title.assignee');

  description = this.I18n.t('js.boards.board_type.action_text_assignee');

  label = this.I18n.t('js.boards.add_list_modal.labels.assignee');

  icon = 'icon-user';

  image = imagePath('board_creation_modal/assignees.svg');

  readonly unassignedUser:any = {
    id: null,
    href: null,
    name: this.I18n.t('js.filter.noneElement'),
  };

  /**
   * Add a single action query
   */
  addColumnWithActionAttribute(board:Board, value:HalResource):Promise<Board> {
    const params:any = {
      name: value.name,
    };

    let filter:ApiV3Filter;

    if (value.id === null) {
      filter = {
        assignee: {
          operator: '!*',
          values: [],
        },
      };
    } else {
      filter = {
        assignee: {
          operator: '=',
          values: [idFromLink(value.href)],
        },
      };
    }

    return this.boardListsService.addQuery(board, params, [filter]);
  }

  /**
   * Returns the current filter value if any
   * @param query
   * @returns The loaded action resource
   */
  getLoadedActionValue(query:QueryResource):Promise<HalResource|undefined> {
    const filter = this.getActionFilter(query);

    // Return the special unassigned user
    if (filter && filter.operator.id === '!*') {
      return Promise.resolve(this.unassignedUser);
    }

    return Promise.resolve(filter?.values[0] as HalResource);
  }

  localizedName = this.I18n.t('js.work_packages.properties.assignee');

  public headerComponent() {
    return AssigneeBoardHeaderComponent;
  }

  public warningTextWhenNoOptionsAvailable(hasMember?:boolean) {
    let text = hasMember
      ? this.I18n.t('js.boards.add_list_modal.warning.assignee')
      : this.I18n.t('js.boards.add_list_modal.warning.no_member');

    return this
      .apiV3Service
      .projects
      .id(this.currentProject.id!)
      .get()
      .toPromise()
      .then((project:ProjectResource) => {
        if (project.memberships) {
          text = text.concat(
            this.I18n.t('js.boards.add_list_modal.warning.add_members', {
              link: this.pathHelper.projectMembershipsPath(this.currentProject.identifier!),
            }),
          );
        }

        return text;
      });
  }

  protected loadUncached():Observable<HalResource[]> {
    return this
      .apiV3Service
      .projects
      .id(this.currentProject.identifier!)
      .available_assignees
      .get()
      .pipe(
        map((collection:CollectionResource<UserResource>) => [this.unassignedUser].concat(collection.elements) as HalResource[]),
      );
  }
}
