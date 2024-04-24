import { Injectable } from '@angular/core';
import { Board } from 'core-app/features/boards/board/board';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import { StateService } from '@uirouter/core';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { VersionBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/version/version-board-header.component';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { VersionAutocompleterComponent } from 'core-app/shared/components/autocompleter/version-autocompleter/version-autocompleter.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  firstValueFrom,
  Observable,
  of,
} from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class BoardVersionActionService extends CachedBoardActionService {
  @InjectField() state:StateService;

  @InjectField() halNotification:HalResourceNotificationService;

  filterName = 'version';

  resourceName = 'version';

  text = this.I18n.t('js.boards.board_type.board_type_title.version');

  description = this.I18n.t('js.boards.board_type.action_text_version');

  label = this.I18n.t('js.boards.add_list_modal.labels.version');

  icon = 'icon-getting-started';

  image = imagePath('board_creation_modal/version.svg');

  private writable$:Promise<boolean>;

  localizedName = this.I18n.t('js.work_packages.properties.version');

  public canAddToQuery(query:QueryResource):Promise<boolean> {
    const formLink = _.get(query, 'results.createWorkPackage.href', null);

    if (!formLink) {
      return Promise.resolve(false);
    }

    if (!this.writable$) {
      this.writable$ = query.results.createWorkPackage()
        .then((form:FormResource) => form.schema.version.writable);
    }

    return this.writable$;
  }

  /**
   * Adds an entry to the list menu to edit the version if allowed
   * @param {QueryResource} query The active query
   * @returns {Promise<any>}
   */
  public getAdditionalListMenuItems(query:QueryResource):Promise<OpContextMenuItem[]> {
    return this
      .getLoadedActionValue(query)
      .then((version:VersionResource) => {
        if (version) {
          return this.buildItemsForVersion(version);
        }
        return [];
      });
  }

  public autocompleterComponent() {
    return VersionAutocompleterComponent;
  }

  public headerComponent() {
    return VersionBoardHeaderComponent;
  }

  public disabledAddButtonPlaceholder(version:VersionResource) {
    if (version.isLocked()) {
      return { icon: 'locked', text: this.I18n.t('js.boards.version.locked') };
    }
    if (version.isClosed()) {
      return { icon: 'not-supported', text: this.I18n.t('js.boards.version.closed') };
    }
    return undefined;
  }

  public dragIntoAllowed(query:QueryResource, value:HalResource|undefined) {
    return value instanceof VersionResource && value.isOpen();
  }

  protected loadUncached():Observable<HalResource[]> {
    if (this.currentProject.id === null) {
      return of([]);
    }

    return this
      .apiV3Service
      .projects
      .id(this.currentProject.id)
      .versions
      .get()
      .pipe(
        map((collection) => collection.elements),
      );
  }

  private patchVersionStatus(version:VersionResource, newStatus:'open'|'closed'|'locked') {
    this.apiV3Service
      .versions
      .id(version)
      .patch({ status: newStatus })
      .subscribe(
        (version) => {
          this.state.go('.', {}, { reload: true });
        },
        (error) => this.halNotification.handleRawError(error),
      );
  }

  private buildItemsForVersion(version:VersionResource):OpContextMenuItem[] {
    const id = version.id!;
    return [
      {
        // Lock version
        hidden: !version.isOpen() || (version.isLocked() && !version.$links.update),
        linkText: this.I18n.t('js.boards.version.lock_version'),
        onClick: () => {
          this.patchVersionStatus(version, 'locked');
          return true;
        },
      },
      {
        // Unlock version
        hidden: !version.isLocked() || (version.isOpen() && !version.$links.update),
        linkText: this.I18n.t('js.boards.version.unlock_version'),
        onClick: () => {
          this.patchVersionStatus(version, 'open');
          return true;
        },
      },
      {
        // Close version
        hidden: version.isClosed() || (!version.isClosed() && !version.$links.update),
        linkText: this.I18n.t('js.boards.version.close_version'),
        onClick: () => {
          this.patchVersionStatus(version, 'closed');
          return true;
        },
      },
      {
        // Open version
        hidden: !version.isClosed() || (version.isClosed() && !version.$links.update),
        linkText: this.I18n.t('js.boards.version.open_version'),
        onClick: () => {
          this.patchVersionStatus(version, 'open');
          return true;
        },
      },
      {
        // Show link
        linkText: this.I18n.t('js.boards.version.show_version'),
        href: this.pathHelper.versionShowPath(id),
        onClick: (evt:JQuery.TriggeredEvent) => {
          if (!isClickedWithModifier(evt)) {
            window.open(this.pathHelper.versionShowPath(id), '_blank');
            return true;
          }

          return false;
        },
      },
      {
        // Edit link
        hidden: !version.$links.update,
        linkText: this.I18n.t('js.boards.version.edit_version'),
        href: this.pathHelper.versionEditPath(id),
        onClick: (evt:JQuery.TriggeredEvent) => {
          if (!isClickedWithModifier(evt)) {
            window.open(this.pathHelper.versionEditPath(id), '_blank');
            return true;
          }

          return false;
        },
      },
    ];
  }
}
