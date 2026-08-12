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

import { OpenProjectModule } from 'core-app/app.module';
import { enableProdMode, provideZonelessChangeDetection } from '@angular/core';

import 'core-app/core/setup/init-js-patches';

import { initializeLocale } from 'core-app/core/setup/init-locale';
import { environment } from './environments/environment';
import { configureErrorReporter } from 'core-app/core/errors/configure-reporter';
import { initializeGlobalListeners } from 'core-app/core/setup/globals/global-listeners';
import { getMetaElement } from 'core-app/core/setup/globals/global-helpers';
import 'core-elements/block-note-element';

import 'core-app/core/setup/init-vendors';
import 'core-app/core/setup/init-globals';
import './stimulus/setup';
import './turbo/setup';
import { platformBrowser } from '@angular/platform-browser';

// Ensure we set the correct dynamic frontend path
// based on the RAILS_RELATIVE_URL_ROOT setting
const ASSET_BASE_PATH = '/assets/frontend/';

// Sets the relative base path
window.appBasePath = getMetaElement('app_base_path')?.content || '';

// Get the asset host, if any
const initializer = getMetaElement('openproject_initializer');
const ASSET_HOST = initializer?.dataset.assetHost ? `//${initializer.dataset.assetHost}` : '';

// Public path prefix used to build absolute asset URLs at runtime
globalThis.publicAssetPath = ASSET_HOST + window.appBasePath + ASSET_BASE_PATH;

window.ErrorReporter = configureErrorReporter();

if (environment.production) {
  enableProdMode();
}

// Import the correct locale early on
void initializeLocale()
  .then(() => {
    initializeGlobalListeners();

    // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
    void platformBrowser().bootstrapModule(OpenProjectModule, { applicationProviders: [provideZonelessChangeDetection()], });
  });
