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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { randomString } from 'core-app/shared/helpers/random-string';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { accessKeys } from 'core-app/shared/directives/a11y/access-keys';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { EditableAttributeFieldComponent } from 'core-app/shared/components/fields/edit/field/editable-attribute-field.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-subject',
  templateUrl: './wp-subject.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WorkPackageSubjectComponent extends UntilDestroyedMixin {
  protected apiV3Service = inject(ApiV3Service);

  private readonly I18n = inject(I18nService);

  private readonly editForm = inject(EditFormComponent, { optional: true });

  protected readonly accessKeys = accessKeys;

  @Input() workPackage:WorkPackageResource;

  public readonly text = {
    edit: this.I18n.t('js.work_packages.button_edit_subject'),
  };

  public readonly uniqueElementIdentifier = `work-packages--subject-type-row-${randomString(16)}`;

  protected editSubject(field:EditableAttributeFieldComponent):void {
    if (field.active) {
      this.editForm?.activeFields[field.fieldName]?.focus();
    } else {
      field.handleUserActivate(null);
    }
  }
}
