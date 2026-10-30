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

// Keeps the NgModule graph in the spec program: @angular/build >= 22.2.0
// ignores the non-declaration `files`/`include` roots of tsconfig.spec.json.
// https://github.com/angular/angular-cli/issues/34231
import type {} from './main';
import { I18n } from 'i18n-js';
import '@testing-library/jest-dom/vitest';
import { afterEach, vi } from 'vitest';
import { registerDialogStreamAction } from 'core-turbo/dialog-stream-action';
import { installElements } from '@openproject/stimulus-elements';

// Blesses every controller registered afterwards with `static elements`
// accessors, mirroring the production bootstrap in stimulus/setup.ts. Must run
// before any controller is registered, so it lives in this global setup file.
installElements();

registerDialogStreamAction();

// Spec files share one browser page, so a pointer left over a later spec's link
// would otherwise start a Turbo hover prefetch through that spec's fetch spy.
const turboPrefetch = document.createElement('meta');
turboPrefetch.name = 'turbo-prefetch';
turboPrefetch.content = 'false';
document.head.append(turboPrefetch);

afterEach(() => {
  vi.useRealTimers();
});

(window as any).global = window;

window.I18n = new I18n();

