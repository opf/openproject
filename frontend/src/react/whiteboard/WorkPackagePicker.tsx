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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import React, { type KeyboardEvent, useEffect, useId, useRef, useState } from 'react';
import {
  formattedId,
  rememberWorkPackage,
  resourceId,
  searchWorkPackages,
  workPackageReference,
  type WorkPackageResource,
} from './work-package-api';
import { workPackageIdFromText } from './work-package-cards';

const SEARCH_DEBOUNCE_MS = 250;

const t = (key:string) => window.I18n.t(`js.whiteboards.work_package_picker.${key}`);

type SearchState =
  | { state:'idle' }
  | { state:'searching' }
  | { state:'done'; results:WorkPackageResource[] }
  | { state:'error' };

function searchTerm(input:string):string {
  const trimmed = input.trim();
  const reference = workPackageIdFromText(trimmed);
  if (!reference) return trimmed;

  return /^\d+$/.test(reference) ? `#${reference}` : reference;
}

function useWorkPackageSearch(input:string):SearchState {
  const [search, setSearch] = useState<SearchState>({ state: 'idle' });

  useEffect(() => {
    const term = searchTerm(input);
    if (!term) {
      setSearch({ state: 'idle' });
      return undefined;
    }

    setSearch({ state: 'searching' });
    const controller = new AbortController();
    const timer = setTimeout(() => {
      searchWorkPackages(term, controller.signal)
        .then((results) => setSearch({ state: 'done', results }))
        .catch(() => {
          if (!controller.signal.aborted) setSearch({ state: 'error' });
        });
    }, SEARCH_DEBOUNCE_MS);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [input]);

  return search;
}

function Option({ workPackage }:{ workPackage:WorkPackageResource }) {
  const { type, project } = workPackage._links;

  return (
    <>
      <span className="op-whiteboard-wp-picker--option-header">
        <span className={`__hl_foreground __hl_uppercase __hl_type_${resourceId(type)}`}>{type?.title}</span>
        <span className="op-whiteboard-wp-picker--muted">{formattedId(workPackageReference(workPackage))}</span>
        <span className="op-whiteboard-wp-picker--muted op-whiteboard-wp-picker--project">{project?.title}</span>
      </span>
      <span className="op-whiteboard-wp-picker--subject">{workPackage.subject}</span>
    </>
  );
}

function statusMessage(search:SearchState):string|null {
  if (search.state === 'idle') return t('hint');
  if (search.state === 'searching') return t('searching');
  if (search.state === 'error') return t('error');
  return search.results.length === 0 ? t('no_results') : null;
}

export interface WorkPackagePickerProps {
  open:boolean;
  showTrigger:boolean;
  onOpenChange:(open:boolean) => void;
  onPick:(reference:string) => void;
}

export function WorkPackagePicker({ open, showTrigger, onOpenChange, onPick }:WorkPackagePickerProps) {
  const [input, setInput] = useState('');
  const [activeIndex, setActiveIndex] = useState(0);
  const search = useWorkPackageSearch(input);
  const results = search.state === 'done' ? search.results : [];
  const containerRef = useRef<HTMLDivElement>(null);
  const listId = useId();
  const optionId = (index:number) => `${listId}-option-${index}`;

  useEffect(() => setActiveIndex(0), [search]);
  useEffect(() => {
    if (!open) {
      setInput('');
      return undefined;
    }

    const closeOnOutsidePress = (event:PointerEvent) => {
      if (!containerRef.current?.contains(event.target as Node)) onOpenChange(false);
    };
    document.addEventListener('pointerdown', closeOnOutsidePress);
    return () => document.removeEventListener('pointerdown', closeOnOutsidePress);
  }, [open, onOpenChange]);

  const pick = (workPackage:WorkPackageResource) => {
    rememberWorkPackage(workPackage);
    onPick(workPackageReference(workPackage));
    onOpenChange(false);
  };

  const onKeyDown = (event:KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      if (results.length === 0) return;
      const step = event.key === 'ArrowDown' ? 1 : -1;
      setActiveIndex((index) => (index + step + results.length) % results.length);
    } else if (event.key === 'Enter') {
      event.preventDefault();
      const workPackage = results[activeIndex];
      if (workPackage) pick(workPackage);
    } else if (event.key === 'Escape') {
      event.preventDefault();
      event.stopPropagation();
      onOpenChange(false);
    }
  };

  const message = statusMessage(search);

  return (
    <div className="op-whiteboard-wp-picker" ref={containerRef}>
      {showTrigger && (
        <button
          type="button"
          className="op-whiteboard-chrome--button op-whiteboard-wp-picker--trigger"
          aria-label={t('button')}
          title={`${t('button')} (#)`}
          aria-expanded={open}
          onClick={() => onOpenChange(!open)}
          data-test-selector="whiteboard-work-package-picker-button"
        >
          #
        </button>
      )}
      {open && (
        <div
          className={`op-whiteboard-wp-picker--popover ${showTrigger ? '' : 'op-whiteboard-wp-picker--popover_sheet'}`}
          data-test-selector="whiteboard-work-package-picker"
        >
          {/* Excalidraw only leaves keystrokes alone in text, number and password inputs; in any other
              input it handles shortcuts like h, Backspace and the arrow keys itself. */}
          <input
            type="text"
            role="combobox"
            autoComplete="off"
            autoCapitalize="off"
            spellCheck={false}
            autoFocus
            aria-label={t('label')}
            aria-expanded={results.length > 0}
            aria-controls={listId}
            aria-activedescendant={results.length > 0 ? optionId(activeIndex) : undefined}
            placeholder={t('placeholder')}
            value={input}
            onChange={(event) => setInput(event.target.value)}
            onKeyDown={onKeyDown}
          />
          {message && <p className="op-whiteboard-wp-picker--status" role="status">{message}</p>}
          <ul id={listId} role="listbox" aria-label={t('label')} className="op-whiteboard-wp-picker--results">
            {results.map((workPackage, index) => (
              <li
                key={workPackage.id}
                id={optionId(index)}
                role="option"
                aria-selected={index === activeIndex}
                className="op-whiteboard-wp-picker--option"
                onMouseEnter={() => setActiveIndex(index)}
                onMouseDown={(event) => event.preventDefault()}
                onClick={() => pick(workPackage)}
              >
                <Option workPackage={workPackage} />
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
