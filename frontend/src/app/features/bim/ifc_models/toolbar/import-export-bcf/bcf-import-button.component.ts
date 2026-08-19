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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { BcfPathHelperService } from 'core-app/features/bim/bcf/helper/bcf-path-helper.service';

@Component({
  template: `
    <a [title]="text.import_hover"
      (click)="handleClick()"
      class="button import-bcf-button">
      <op-icon icon-classes="button--icon icon-import" />
      <span class="button--text"> {{text.import}} </span>
    </a>
  `,
  selector: 'bcf-import-button',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class BcfImportButtonComponent {
  readonly I18n = inject(I18nService);
  readonly currentProject = inject(CurrentProjectService);
  readonly bcfPathHelper = inject(BcfPathHelperService);

  public text = {
    import: this.I18n.t('js.bcf.import'),
    import_hover: this.I18n.t('js.bcf.import_bcf_xml_file'),
  };

  public handleClick() {
    const projectIdentifier = this.currentProject.identifier;
    if (projectIdentifier) {
      const url = this.bcfPathHelper.projectImportIssuePath(projectIdentifier);
      window.location.href = url;
    }
  }
}
