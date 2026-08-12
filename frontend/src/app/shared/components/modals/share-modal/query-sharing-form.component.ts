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

import { States } from 'core-app/core/states/states.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

export interface QuerySharingChange {
  isStarred:boolean;
  isPublic:boolean;
}

@Component({
  selector: 'query-sharing-form',
  templateUrl: './query-sharing-form.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class QuerySharingFormComponent {
  readonly states = inject(States);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly authorisationService = inject(AuthorisationService);
  readonly I18n = inject(I18nService);

  @Input() public isSave:boolean;

  @Input() public isStarred:boolean;

  @Input() public isPublic:boolean;

  @Output() public onChange = new EventEmitter<QuerySharingChange>();

  public text = {
    showInMenu: this.I18n.t('js.label_star_query'),
    visibleForOthers: this.I18n.t('js.label_public_query'),

    showInMenuText: this.I18n.t('js.work_packages.query.star_text'),
    visibleForOthersText: this.I18n.t('js.work_packages.query.public_text'),
  };

  public get canStar() {
    return this.isSave
      || this.authorisationService.can('query', 'star')
      || this.authorisationService.can('query', 'unstar');
  }

  public get canPublish() {
    const form = this.querySpace.queryForm.value!;

    return this.authorisationService.can('query', 'updateImmediately')
      && form.schema.public.writable;
  }

  public updateStarred(val:boolean) {
    this.isStarred = val;
    this.changed();
  }

  public updatePublic(val:boolean) {
    this.isPublic = val;
    this.changed();
  }

  public changed() {
    this.onChange.emit({ isStarred: !!this.isStarred, isPublic: !!this.isPublic });
  }
}
