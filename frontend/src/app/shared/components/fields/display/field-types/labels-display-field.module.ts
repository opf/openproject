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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ResourcesDisplayField } from './resources-display-field.module';

function span(text:string, ...classes:string[]):HTMLSpanElement {
  const el = document.createElement('span');
  el.classList.add(...classes);
  el.textContent = text;
  return el;
}

export class LabelsDisplayField extends ResourcesDisplayField {
  protected renderValues(_values:string[], element:HTMLElement):void {
    const isSingleView = this.context.container === 'single-view';
    const { resources } = this;
    const visible = isSingleView ? resources : resources.slice(0, 2);

    const container = document.createElement('div');
    container.classList.add('op-labels-display-field', 'd-inline-flex', 'flex-items-center', 'gap-1', 'v-align-middle');
    container.classList.toggle('flex-wrap', isSingleView);

    visible.forEach(({ name }) => {
      const label = span(name, 'Label');
      label.classList.toggle('Label--large', isSingleView);
      container.append(label);
    });

    if (resources.length > visible.length) {
      container.append('...', span(resources.length.toString(), 'badge'));
    }

    element.append(container);
  }
}
