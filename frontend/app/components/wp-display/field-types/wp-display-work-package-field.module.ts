// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {DisplayField} from "../wp-display-field/wp-display-field.module";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {UiStateLinkBuilder} from '../../wp-fast-table/builders/ui-state-link-builder';

export class WorkPackageDisplayField extends DisplayField {
  public text:{ linkTitle:string, none:string };
  private uiStateBuilder:UiStateLinkBuilder;


  constructor(public resource:WorkPackageResource,
              public name:string,
              public schema:op.FieldSchema) {
    super(resource, name, schema);

    this.uiStateBuilder = new UiStateLinkBuilder();
    this.text = {
      linkTitle: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen'),
      none: this.I18n.t('js.filter.noneElement')
    };
  }

  public render(element:HTMLElement, displayText:string): void {
    if (this.isEmpty()) {
      element.innerText = this.placeholder;
      return;
    }

    let link = this.uiStateBuilder.linkToShow(
      this.wpId,
      this.text.linkTitle,
      this.valueString
    );

    element.innerHTML = '';
    element.appendChild(link);
  }

  public get value() {
    return this.resource[this.name];
  }

  public get title() {
    if (this.isEmpty()) {
      return this.text.none;
    } else {
      return this.value.name;
    }
  }

  public get wpId() {
    if (this.isEmpty()) {
      return null;
    }

    if (this.value.$loaded) {
      return this.value.id;
    }

    // Read WP ID from href
    return this.value.href.match(/(\d+)$/)[0];
  }

  public get writable():boolean {
    return false;
  }

  public get valueString() {
    return "#" + this.wpId;
  }

  public isEmpty(): boolean {
    return !this.value;
  }

  public get unknownAttribute():boolean {
    return false;
  }

}
