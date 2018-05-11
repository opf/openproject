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
import {StatusResource} from 'core-app/modules/hal/resources/status-resource';
import {States} from "core-components/states.service";
import {HalResource} from "app/modules/hal/resources/hal-resource";

interface ColoredHalResource extends HalResource {
  name:string;
  color?:string;
}

// We need the loaded resource for the given resource since the color
// is not always embedded. Thus restrict attributes to what we can load beforehand.
export type ColoredAttributes = 'status' | 'priority';

export class ColoredDisplayField extends DisplayField {

  constructor(public resource:HalResource,
              public coloredAttribute:ColoredAttributes,
              public schema:op.FieldSchema) {
    super(resource, coloredAttribute, schema);
  }

  readonly states:States = this.$injector.get(States);

  public get value():ColoredHalResource {
    return this.resource[this.name];
  }

  public get valueString() {
    return this.value.name;
  }

  public get coloredResourceCache():string {
    return {
      status: 'statuses',
      priority: 'priorities'
    }[this.coloredAttribute];
  }

  public get resourceId() {
    return this.value.idFromLink;
  }

  public get loadedColorResource():ColoredHalResource {
    return (this.states as any)[this.coloredResourceCache]
      .get(this.resourceId)
      .getValueOr(this.value);
  }

  public render(element:HTMLElement, displayText:string):void {
    const colored = this.loadedColorResource;
    element.setAttribute('title', displayText);

    const color = document.createElement('span');

    color.classList.add('wp-display-field--color');

    const text = document.createElement('span');
    text.classList.add('wp-display-field--color-text');
    text.textContent = displayText;

    if (colored.color) {
      color.style.backgroundColor = colored.color;
      text.style.color = colored.color;
    }

    element.appendChild(color);
    element.appendChild(text);
  }
}
