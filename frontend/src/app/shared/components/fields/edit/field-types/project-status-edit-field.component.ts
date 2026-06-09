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

import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { NgSelectComponent } from '@ng-select/ng-select';
import {
  projectStatusCodeCssClass,
  projectStatusI18n,
} from 'core-app/shared/components/fields/helpers/project-status-helper';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { repositionDropdownBugfix } from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';
import { target } from 'core-app/shared/helpers/event-helpers';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

interface ProjectStatusOption {
  href:string
  name:string
  colorClass:string
}

interface ProjectStatusResource extends HalResource {
  status:{ href:string }|null;
}

@Component({
  templateUrl: './project-status-edit-field.component.html',
  styleUrls: ['./project-status-edit-field.component.sass'],
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class ProjectStatusEditFieldComponent extends EditFieldComponent implements OnInit {
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  public availableStatuses:ProjectStatusOption[] = [{
    href: 'not_set',
    name: projectStatusI18n('not_set', this.I18n),
    colorClass: projectStatusCodeCssClass('not_set'),
  }];

  public currentStatusCode:string;

  public hiddenOverflowContainer = '#content-wrapper';

  public appendToContainer = 'body';

  ngOnInit() {
    this.currentStatusCode = this.projectStatusResource.status?.href ?? this.availableStatuses[0].href;
    void this.loadAvailableStatuses();
  }

  public onChange() {
    this.projectStatusResource.status = this.currentStatusCode === this.availableStatuses[0].href ? null : { href: this.currentStatusCode };
    void this.handler.handleUserSubmit();
  }

  public onOpen() {
    repositionDropdownBugfix(this.ngSelectComponent);

    target(document.querySelector(this.hiddenOverflowContainer)!).one('scroll.autocompleteContainer', () => {
      this.ngSelectComponent.close();
    });
  }

  public onClose() {
    target(document.querySelector(this.hiddenOverflowContainer)!).off('scroll.autocompleteContainer');
  }

  private get projectStatusResource():ProjectStatusResource {
    return this.resource as ProjectStatusResource;
  }

  private async loadAvailableStatuses():Promise<void> {
    await this.change.getForm();
    const statusSchema = (this.change.schema as { status?:IFieldSchema }).status;
    const allowedValues = (statusSchema?.allowedValues ?? []) as HalResource[];

    this.availableStatuses = [
      ...this.availableStatuses,
      ...allowedValues.map((status:HalResource) => ({
        href: status.href!,
        name: status.name,
        colorClass: projectStatusCodeCssClass(status.id),
      })),
    ];
    this.cdRef.markForCheck();

    // The timeout takes care that the opening is added to the end of the current call stack.
    // Thus we can be sure that the select box is rendered and ready to be opened.
    window.setTimeout(() => {
      this.ngSelectComponent.open();
    }, 0);
  }
}
