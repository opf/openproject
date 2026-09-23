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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, inject } from '@angular/core';
import { finalize } from 'rxjs/operators';
import { HttpClient } from '@angular/common/http';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import {
  IApiLabel,
  ILabelAutocompleteItem,
  LabelsAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/labels-autocompleter/labels-autocompleter.component';

@Component({
  selector: 'op-create-label-button',
  templateUrl: './create-label-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class CreateLabelButtonComponent {
  @Input() searchTerm = '';

  readonly I18n = inject(I18nService);
  readonly http = inject(HttpClient);
  readonly apiV3Service = inject(ApiV3Service);
  readonly halNotification = inject(HalResourceNotificationService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly autocompleter = inject(OpAutocompleterComponent) as LabelsAutocompleterComponent;

  public creating = false;

  public get trimmedSearchTerm():string {
    return (this.searchTerm ?? '').trim();
  }

  public buttonText():string {
    return this.I18n.t('js.autocompleter.create_label', { name: this.trimmedSearchTerm });
  }

  public showCreateOption(items:ILabelAutocompleteItem[]|null):boolean {
    const term = this.trimmedSearchTerm;
    if (!term) {
      return false;
    }

    const normalizedTerm = this.normalize(term);
    return !(items ?? []).some((item) => this.normalize(item.name) === normalizedTerm);
  }

  public onCreateClick(event:Event):void {
    event.stopPropagation();
    const name = this.trimmedSearchTerm;
    if (!name || this.creating) {
      return;
    }

    this.creating = true;

    this
      .http
      .post<IApiLabel>(this.apiV3Service.labels.toString(), { name })
      .pipe(
        finalize(() => {
          this.creating = false;
          this.cdRef.markForCheck();
        }),
      )
      .subscribe({
        next: (label) => this.addLabel(label),
        error: (error) => this.halNotification.handleRawError(error),
      });
  }

  private addLabel(label:IApiLabel):void {
    const created:ILabelAutocompleteItem = { id: label.id, name: label.name, href: label._links.self.href };
    const current = Array.isArray(this.autocompleter.model) ? this.autocompleter.model : [];

    if (!current.some((item) => item.href === created.href)) {
      this.autocompleter.changed([...current, created]);
    }

    this.autocompleter.ngSelectInstance.filter('');
  }

  private normalize(value:string):string {
    return value.trim().replace(/\s+/g, ' ').toLowerCase();
  }
}
