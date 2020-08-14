import {Injectable} from "@angular/core";
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {AssigneeBoardHeaderComponent} from "core-app/modules/boards/board/board-actions/assignee/assignee-board-header.component";
import {ProjectResource} from "core-app/modules/hal/resources/project-resource";
import {CachedBoardActionService} from "core-app/modules/boards/board/board-actions/cached-board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Injectable()
export class BoardAssigneeActionService extends CachedBoardActionService {
  filterName = 'assignee';

  text = this.I18n.t('js.boards.board_type.action_by_attribute',
  { attribute: this.I18n.t('js.boards.board_type.action_type.assignee')});

  description = this.I18n.t('js.boards.board_type.action_text',
  { attribute: this.I18n.t('js.boards.board_type.action_type.assignee')});

  icon = 'icon-user';

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.assignee');
  }

  public headerComponent() {
    return AssigneeBoardHeaderComponent;
  }

  public warningTextWhenNoOptionsAvailable() {
    let text = this.I18n.t('js.boards.add_list_modal.warning.assignee');

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
              link: this.pathHelper.projectMembershipsPath(this.currentProject.identifier!)
            })
          );
        }

        return text;
      });
  }

  protected loadUncached():Promise<HalResource[]> {
    return this
      .apiV3Service
      .projects
      .id(this.currentProject.identifier!)
      .available_assignees
      .get()
      .toPromise()
      .then((collection:CollectionResource<UserResource>) => collection.elements);
  }
}
