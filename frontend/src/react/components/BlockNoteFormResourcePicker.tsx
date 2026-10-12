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

import { createElement, useEffect, useRef } from 'react';
import type { NgElement, WithProperties } from '@angular/elements';
import type { FormResourcePickerProps } from '@openproject/blocknote-extensions/primer';
import type { IProjectAutocompleterData } from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter.component';
import { isRecord } from 'core-app/shared/helpers/type-guards';

type PickerElement = NgElement & WithProperties<{ model:IProjectAutocompleterData | null; inputAttrs:Record<string, string> }>;

export function BlockNoteFormResourcePicker({
  resource, id, label, href, value, valueLabel, placeholder, invalid, describedBy, onChange,
}:FormResourcePickerProps) {
  const ref = useRef<PickerElement>(null);
  const project = resource === 'project';
  const tag = project ? 'opce-project-autocompleter' : 'opce-user-autocompleter';

  useEffect(() => {
    const element = ref.current;
    if (!element) return undefined;

    const change = (event:Event) => {
      if (!(event instanceof CustomEvent)) return;
      const item:unknown = event.detail;
      if (item == null) onChange('');
      else if (isRecord(item) && typeof item.href === 'string' && typeof item.name === 'string') {
        onChange(item.href, item.name);
      }
    };
    element.addEventListener('change', change);
    return () => element.removeEventListener('change', change);
  }, [onChange]);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    void customElements.whenDefined(tag).then(() => {
      if (ref.current !== element) return;
      if (value && element.model?.href === value && element.model.name === valueLabel) return;
      element.model = value ? { id: value.split('/').pop() ?? value, href: value, name: valueLabel ?? '' } : null;
    });
  }, [tag, value, valueLabel]);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    void customElements.whenDefined(tag).then(() => {
      if (ref.current === element) {
        element.inputAttrs = { 'aria-invalid': String(Boolean(invalid)), 'aria-describedby': describedBy ?? '' };
      }
    });
  }, [tag, invalid, describedBy]);

  return createElement(tag, {
    ref,
    id: `${id}-picker`,
    className: 'op-angular-component',
    style: { width: '100%', position: 'relative' },
    'data-url': JSON.stringify(href),
    'data-default-data': 'false',
    'data-defer-fetch-until-opened': 'true',
    'data-filters': project ? JSON.stringify([{ name: 'active', operator: '=', values: ['t'] }]) : undefined,
    'data-placeholder': JSON.stringify(placeholder),
    'data-label-for-id': JSON.stringify(id),
    'data-aria-label': JSON.stringify(label),
    'data-focus-directly': 'false',
    'data-append-to': JSON.stringify(`#${CSS.escape(id)}-picker`),
  });
}
