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
//++

import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { Component, OnInit, ViewChild } from "@angular/core";
import { EditFieldComponent } from "core-app/modules/fields/edit/edit-field.component";
import { NgSelectComponent } from "@ng-select/ng-select";
import { projectStatusCodeCssClass, projectStatusI18n } from "core-app/modules/fields/helpers/project-status-helper";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

@Component({
  templateUrl: './project-status-edit-field.component.html',
  styleUrls: ['./project-status-edit-field.component.sass']
})
export class ProjectStatusEditFieldComponent extends EditFieldComponent implements OnInit {
  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;
  @InjectField() I18n!:I18nService;

  private _availableStatusCodes:string[] = ['not set', 'off track', 'at risk', 'on track'];
  public currentStatusCode = 'not set';

  public availableStatuses:any[] = this._availableStatusCodes.map((code:string):any => {
    return {
      code: code,
      name: projectStatusI18n(code, this.I18n),
      colorClass: projectStatusCodeCssClass(code)
    };
  });

  public hiddenOverflowContainer = '#content-wrapper';
  public appendToContainer = 'body';

  ngOnInit() {
    this.currentStatusCode = this.resource['status'] === null ? 'not set' : this.resource['status'];

    // The timeout takes care that the opening is added to the end of the current call stack.
    // Thus we can be sure that the select box is rendered and ready to be opened.
    const that = this;
    window.setTimeout(function () {
      that.ngSelectComponent.open();
    }, 0);
  }

  public onChange() {
    this.resource['status'] = this.currentStatusCode === 'not set' ? null : this.currentStatusCode;
    this.handler.handleUserSubmit();
  }

  public onOpen() {
    // Force reposition as a workaround for BUG
    // https://github.com/ng-select/ng-select/issues/1259
    setTimeout(() => {
      const component = (this.ngSelectComponent) as any;
      if (component && component.dropdownPanel) {
        component.dropdownPanel._updatePosition();
      }

      jQuery(this.hiddenOverflowContainer).one('scroll.autocompleteContainer', () => {
        this.ngSelectComponent.close();
      });
    }, 25);
  }

  public onClose() {
    jQuery(this.hiddenOverflowContainer).off('scroll.autocompleteContainer');
  }
}
