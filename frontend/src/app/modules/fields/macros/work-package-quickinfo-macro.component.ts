//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++    Ng1FieldControlsWrapper,

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, HostBinding, Injector } from "@angular/core";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { Observable } from "rxjs";
import { tap } from "rxjs/operators";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { DisplayFieldService } from "core-app/modules/fields/display/display-field.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { DateDisplayField } from "core-app/modules/fields/display/field-types/date-display-field.module";
import { CombinedDateDisplayField } from "core-app/modules/fields/display/field-types/combined-date-display.field";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";

export const quickInfoMacroSelector = 'macro.macro--wp-quickinfo';

@Component({
  selector: quickInfoMacroSelector,
  templateUrl: './work-package-quickinfo-macro.html',
  styleUrls: ['./work-package-quickinfo-macro.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService
  ]
})
export class WorkPackageQuickinfoMacroComponent {
  // Whether the value could not be loaded
  error:string|null = null;

  text = {
    not_found: this.I18n.t('js.editor.macro.attribute_reference.not_found'),
    help: this.I18n.t('js.editor.macro.attribute_reference.macro_help_tooltip')
  };

  @HostBinding('title') hostTitle = this.text.help;

  /** Work package to be shown */
  workPackage$:Observable<WorkPackageResource>;
  dateDisplayField = CombinedDateDisplayField;
  workPackageLink:string;
  detailed = false;

  constructor(readonly elementRef:ElementRef,
              readonly injector:Injector,
              readonly apiV3Service:APIV3Service,
              readonly schemaCache:SchemaCacheService,
              readonly displayField:DisplayFieldService,
              readonly pathHelper:PathHelperService,
              readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef) {

  }

  ngOnInit() {
    const element = this.elementRef.nativeElement as HTMLElement;
    const id:string = element.dataset.id!;
    this.detailed = element.dataset.detailed === 'true';
    this.workPackageLink = this.pathHelper.workPackagePath(id);

    this.workPackage$ = this
      .apiV3Service
      .work_packages
      .id(id)
      .get()
      .pipe(
        tap({ error: (e) => this.markError(this.text.not_found) })
      );
  }

  markError(message:string) {
    console.error("Failed to render macro " + message);
    this.error = this.I18n.t('js.editor.macro.error', { message: message });
    this.cdRef.detectChanges();
  }
}
