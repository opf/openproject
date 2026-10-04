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

import React, { type FormEvent, type KeyboardEvent, useState } from 'react';
import { workPackageIdFromText } from './work-package-cards';

const t = (key:string) => window.I18n.t(`js.whiteboards.add_work_package.${key}`);

export function AddWorkPackageCard({ onAdd }:{ onAdd:(id:string) => void }) {
  const [open, setOpen] = useState(false);
  const [value, setValue] = useState('');
  const [invalid, setInvalid] = useState(false);

  const close = () => {
    setOpen(false);
    setValue('');
    setInvalid(false);
  };

  const submit = (event:FormEvent) => {
    event.preventDefault();
    const id = workPackageIdFromText(value);
    if (!id) {
      setInvalid(true);
      return;
    }
    onAdd(id);
    close();
  };

  const closeOnEscape = (event:KeyboardEvent) => {
    if (event.key === 'Escape') close();
  };

  return (
    <div className="op-whiteboard-add-wp">
      <button
        type="button"
        className="op-whiteboard-chrome--button"
        aria-label={t('button')}
        title={t('button')}
        aria-expanded={open}
        onClick={() => (open ? close() : setOpen(true))}
        data-test-selector="whiteboard-add-work-package"
      >
        <svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
          <path d="m7.775 3.275 1.25-1.25a3.5 3.5 0 1 1 4.95 4.95l-2.5 2.5a3.5 3.5 0 0 1-4.95 0 .751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018 1.998 1.998 0 0 0 2.83 0l2.5-2.5a2.002 2.002 0 0 0-2.83-2.83l-1.25 1.25a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042Zm-4.69 9.64a1.998 1.998 0 0 0 2.83 0l1.25-1.25a.751.751 0 0 1 1.042.018.751.751 0 0 1 .018 1.042l-1.25 1.25a3.5 3.5 0 1 1-4.95-4.95l2.5-2.5a3.5 3.5 0 0 1 4.95 0 .751.751 0 0 1-.018 1.042.751.751 0 0 1-1.042.018 1.998 1.998 0 0 0-2.83 0l-2.5 2.5a1.998 1.998 0 0 0 0 2.83Z" />
        </svg>
      </button>
      {open && (
        <form className="op-whiteboard-add-wp--form" onSubmit={submit} onKeyDown={closeOnEscape}>
          <input
            type="text"
            inputMode="url"
            autoComplete="off"
            autoCapitalize="off"
            spellCheck={false}
            autoFocus
            aria-label={t('label')}
            placeholder={t('placeholder')}
            aria-invalid={invalid}
            value={value}
            onChange={(event) => {
              setValue(event.target.value);
              setInvalid(false);
            }}
            data-test-selector="whiteboard-add-work-package-input"
          />
          <button type="submit">{t('submit')}</button>
          {invalid && <p className="op-whiteboard-add-wp--error" role="alert">{t('invalid')}</p>}
        </form>
      )}
    </div>
  );
}
