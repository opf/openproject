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

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Component, OnInit, ViewChild } from '@angular/core';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { NgSelectComponent } from '@ng-select/ng-select';
import {
  projectStatusCodeCssClass,
  projectStatusI18n,
} from 'core-app/shared/components/fields/helpers/project-status-helper';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { repositionDropdownBugfix } from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';

interface ProjectStatusOption {
  href:string
  name:string
  colorClass:string
}

@Component({
  templateUrl: './project-status-edit-field.component.html',
  styleUrls: ['./project-status-edit-field.component.sass'],
})
export class ProjectStatusEditFieldComponent extends EditFieldComponent implements OnInit {
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  @InjectField() I18n!:I18nService;

  public availableStatuses:ProjectStatusOption[] = [{
    href: 'not_set',
    name: projectStatusI18n('not_set', this.I18n),
    colorClass: projectStatusCodeCssClass('not_set'),
  }];

  public currentStatusCode:string;

  public hiddenOverflowContainer = '#content-wrapper';

  public appendToContainer = 'body';

  ngOnInit() {
    this.currentStatusCode = this.resource.status === null ? this.availableStatuses[0].href : this.resource.status.href;

    this.change.getForm().then((form) => {
      form.schema.status.allowedValues.forEach((status:HalResource) => {
        this.availableStatuses = [...this.availableStatuses,
          {
            href: status.href!,
            name: status.name,
            colorClass: projectStatusCodeCssClass(status.id),
          }];
      });

      // The timeout takes care that the opening is added to the end of the current call stack.
      // Thus we can be sure that the select box is rendered and ready to be opened.
      const that = this;
      window.setTimeout(() => {
        that.ngSelectComponent.open();
      }, 0);
    });
  }

  public onChange() {
    this.resource.status = this.currentStatusCode === this.availableStatuses[0].href ? null : { href: this.currentStatusCode };
    this.handler.handleUserSubmit();
  }

  public onOpen() {
    repositionDropdownBugfix(this.ngSelectComponent);

    jQuery(this.hiddenOverflowContainer).one('scroll.autocompleteContainer', () => {
      this.ngSelectComponent.close();
    });
  }

  public onClose() {
    jQuery(this.hiddenOverflowContainer).off('scroll.autocompleteContainer');
  }
}
