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

import { Injectable, inject } from '@angular/core';
import { Board } from 'core-app/features/boards/board/board';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { VersionBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/version/version-board-header.component';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { VersionAutocompleterComponent } from 'core-app/shared/components/autocompleter/version-autocompleter/version-autocompleter.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import {
  firstValueFrom,
  Observable,
  of,
} from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class BoardVersionActionService extends CachedBoardActionService {
  readonly halNotification = inject(HalResourceNotificationService);

  filterName = 'version';

  /**
   * Board queries created here send "version", but the server normalizes the
   * stored key to whichever of the interchangeable version filters is
   * available, so the API may render the filter under either id.
   */
  override get filterNames():string[] {
    return ['version', 'targetVersion'];
  }

  /**
   * The list-defining filter stays "version" (stored in board queries), while
   * assigning a card writes the targetVersions attribute (see attributeName).
   *
   * Both keys have to be watched: with Setting::WorkPackageMultipleVersions
   * disabled, Type::Attributes still offers the deprecated single "version" in
   * the work package form, so an edit in the full or split view commits that
   * key and a card would otherwise stay in its old list until a page reload.
   *
   * TODO: reduce this to the default [this.attributeName] once the deprecated
   * version attribute is no longer offered in the form.
   */
  override get watchedAttributes():string[] {
    return [this.attributeName, this.filterName];
  }

  resourceName = 'version';

  text = this.I18n.t('js.boards.board_type.board_type_title.version');

  description = this.I18n.t('js.boards.board_type.action_text_version');

  label = this.I18n.t('js.boards.add_list_modal.labels.version');

  icon = 'icon-getting-started';

  image = imagePath('board_creation_modal/version.svg');

  private writable$:Promise<boolean>;

  localizedName = this.I18n.t('js.work_packages.properties.version');

  public canAddToQuery(query:QueryResource):Promise<boolean> {
    const formLink = (query?.results?.createWorkPackage as { href?:string }|undefined)?.href ?? null;

    if (!formLink) {
      return Promise.resolve(false);
    }

    if (!this.writable$) {
      const createForm = query.results.createWorkPackage as () => Promise<FormResource>;

      this.writable$ = createForm()
        .then((form:FormResource) => (form.schema[this.attributeName] as IFieldSchema).writable);
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
        () => {
          Turbo.visit(window.location.href, { action: 'replace' });
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
        onClick: (evt) => {
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
        onClick: (evt) => {
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
