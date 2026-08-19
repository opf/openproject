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

import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { CreateAutocompleterComponent } from '../create-autocompleter/create-autocompleter.component';
import { opPhaseIconData, toDOMString } from '@openproject/octicons-angular';
import { ProjectPhaseResource } from 'core-app/features/hal/resources/project-phase-resource';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  templateUrl: './project-phase-autocompleter.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
// It would have been cleaner to extend the OpAutocompleter component as there is no intention to create a
// Project phase here. But the OpAutocompleter does not satisfy the interface the template of the
// SelectEditFieldComponent is calling.
export class ProjectPhaseAutocompleterComponent extends CreateAutocompleterComponent {
  readonly sanitizer = inject(DomSanitizer);

  public phaseIcon:SafeHtml;

  constructor() {
    super();

    this.phaseIcon = this.sanitizer.bypassSecurityTrustHtml(toDOMString(opPhaseIconData, 'small', { 'aria-hidden': 'true', class: 'octicon' }));
  }

  public isPhase(item:ProjectPhaseResource|HalLink) {
    return Object.prototype.hasOwnProperty.call(item, 'definition');
  }

  public iconClasses(projectPhase:ProjectPhaseResource) {
    return `__hl_inline_project_phase_definition_${projectPhase.definition.id} mr-1`;
  }
}
