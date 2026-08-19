/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { opPhaseIconData, toDOMString } from '@openproject/octicons-angular';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ProjectPhaseResource } from 'core-app/features/hal/resources/project-phase-resource';

export class ProjectPhaseDisplayField extends DisplayField {
  public get value():string|null {
    if (this.schema && this.attribute) {
      return (this.attribute as ProjectPhaseResource).name;
    }
    return null;
  }

  public render(element:HTMLElement, displayText:string):void {
    super.render(element, displayText);

    element.prepend(this.phaseIcon());
  }

  /**
   * Creates and returns an HTML element representing the icon for a project phase.
   * The icon is wrapped in a span element with the correct css class set for coloring
   * the icon in the color defined for the definition.
   *
   * @param phaseDefinitionId The ID of the phase definition (used for CSS class)
   * @param addPadding Whether to add right margin padding
   * @return {HTMLElement} The HTML span element containing the project phase icon.
   * @see phaseIcon
   */
  public static phaseIconById(phaseDefinitionId?:string, addPadding = true) {
    const icon = document.createElement('span');

    if (phaseDefinitionId) {
      if (addPadding) {
        icon.classList.add('mr-1');
      }

      icon.setAttribute('data-test-selector', `project-phase-icon phase-definition-${phaseDefinitionId}`);

      icon.innerHTML = toDOMString(
        opPhaseIconData,
        'small',
        { 'aria-hidden': 'true', class: 'octicon' },
      );

      // Use the phase definition ID for the CSS class.
      // This is more robust than using the name as it avoids issues with special characters.
      icon.classList.add(`__hl_inline_project_phase_definition_${phaseDefinitionId}`);
    }

    return icon;
  }

  /**
   * @see phaseIconById
   */
  protected phaseIcon():HTMLElement {
    const definition = this.resource.projectPhaseDefinition as HalResource;
    return ProjectPhaseDisplayField.phaseIconById(definition?.id ?? undefined);
  }
}
