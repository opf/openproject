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
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {ColorContrast} from "core-components/a11y/color-contrast.functions";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";

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
  readonly wpTableHighlighting:WorkPackageTableHighlightingService = this.$injector.get(WorkPackageTableHighlightingService);

  public get value():ColoredHalResource {
    return this.resource[this.name];
  }

  public get valueString() {
    return this.value.name;
  }

  public get resourceId() {
    return this.value.idFromLink;
  }

  public get shouldHighlight() {
    return this.wpTableHighlighting.isDefault;
  }

  public render(element:HTMLElement, displayText:string):void {
    if (!this.shouldHighlight) {
      super.render(element, displayText);
      return;
    }

    const colored = this.wpTableHighlighting.getHighlightResource(this.coloredAttribute, this.value);

    element.setAttribute('title', displayText);
    element.classList.add('wp-display-field--color-text');
    element.textContent = displayText;

    if (colored.color) {
      const patch = ColorContrast.getColorPatch(colored.color);
      element.style.color = patch.fg;
      element.style.backgroundColor = patch.bg;
    }
  }
}
