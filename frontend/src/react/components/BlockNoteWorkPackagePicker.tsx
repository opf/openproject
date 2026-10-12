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
import type { WorkPackagePickerProps } from '@openproject/blocknote-extensions/primer';
import type { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { formatWorkPackageId } from 'core-app/shared/helpers/work-package-id-pattern';

type PickerElement = NgElement & WithProperties<Pick<OpAutocompleterComponent, 'model'>>;

export function BlockNoteWorkPackagePicker({ id, label, autoFocus, selected, onPick, onDeselect }:WorkPackagePickerProps) {
  const ref = useRef<PickerElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) return undefined;

    const change = (event:Event) => {
      if (!(event instanceof CustomEvent)) return;
      const item:unknown = event.detail;
      if (item == null) {
        onDeselect();
      } else if (typeof item === 'object' && 'id' in item && 'subject' in item && typeof item.subject === 'string') {
        const selectedId = Number(item.id);
        if (!Number.isSafeInteger(selectedId) || selectedId <= 0) return;
        const displayId = 'displayId' in item && typeof item.displayId === 'string' ? item.displayId : String(selectedId);
        onPick({ id: selectedId, displayId, subject: item.subject });
      }
    };
    element.addEventListener('change', change);
    return () => element.removeEventListener('change', change);
  }, [onPick, onDeselect]);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    void customElements.whenDefined('opce-autocompleter').then(() => {
      if (ref.current !== element) return;
      const current = element.model;
      if (current && typeof current === 'object' && 'id' in current && Number(current.id) === selected?.id) return;
      element.model = selected ? {
        id: selected.id,
        formattedId: formatWorkPackageId(selected.displayId),
        subject: selected.subject,
      } : null;
    });
  }, [selected]);

  return createElement('opce-autocompleter', {
    ref,
    id: `${id}-picker`,
    className: 'op-angular-component',
    'data-resource': JSON.stringify('work_packages'),
    'data-search-key': JSON.stringify('typeahead'),
    'data-default-data': 'true',
    'data-append-to': JSON.stringify(`#${CSS.escape(id)}-picker`),
    'data-label-for-id': JSON.stringify(id),
    'data-aria-label': JSON.stringify(label),
    'data-focus-directly': JSON.stringify(Boolean(autoFocus)),
    'data-clear-search-on-add': 'false',
  });
}
