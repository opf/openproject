import {Injectable} from "@angular/core";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {buildApiV3Filter} from "core-components/api/api-v3/api-v3-filter-builder";
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {input} from "reactivestates";
import {take} from "rxjs/operators";
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {SubprojectBoardHeaderComponent} from "core-app/modules/boards/board/board-actions/subproject/subproject-board-header.component";

@Injectable()
export class BoardSubprojectActionService extends BoardActionService {
  filterName = 'onlySubproject';

  private subprojects = input<HalResource[]>();

  get localizedName() {
    return this.I18n.t('js.work_packages.properties.subproject');
  }

  headerComponent() {
    return SubprojectBoardHeaderComponent;
  }

  // TODO need permission for user on subproject
  canMove(workPackage:WorkPackageResource):boolean {
    return true;
  }

  // TODO assign subproject to changeset
  assignToWorkPackage(changeset:WorkPackageChangeset, query:QueryResource) {
    const href = this.getActionValueHrefForColumn(query);
    changeset.setValue('project', { href: href });
  }

  protected loadAvailable():Promise<HalResource[]> {
    const currentProjectId = this.currentProject.id!;
    this.subprojects.putFromPromiseIfPristine(() =>
      this
        .apiV3Service
        .projects
        .filtered(buildApiV3Filter('ancestor', '=', currentProjectId))
        .get()
        .toPromise()
        .then((collection:CollectionResource<UserResource>) => collection.elements)
    );

    return this.subprojects
      .values$()
      .pipe(take(1))
      .toPromise();
  }

}
