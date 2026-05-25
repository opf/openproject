import { OpenProjectModule } from 'core-app/app.module';
import { enableProdMode, provideZonelessChangeDetection } from '@angular/core';

import 'core-app/core/setup/init-jquery';
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
// https://webpack.js.org/guides/public-path/
const ASSET_BASE_PATH = '/assets/frontend/';
const _BUILD = 2;

// Sets the relative base path
window.appBasePath = getMetaElement('app_base_path')?.content || '';

// Get the asset host, if any
const initializer = getMetaElement('openproject_initializer');
const ASSET_HOST = initializer?.dataset.assetHost ? `//${initializer.dataset.assetHost}` : '';

// Ensure to set the asset base for dynamic code loading
// https://webpack.js.org/guides/public-path/
// eslint-disable-next-line no-underscore-dangle
globalThis.__webpack_public_path__ = ASSET_HOST + window.appBasePath + ASSET_BASE_PATH;

window.ErrorReporter = configureErrorReporter();

if (environment.production) {
  enableProdMode();
}

// Register ELO service worker for PWA installability and future push support
if ('serviceWorker' in navigator) {
  void navigator.serviceWorker.register('/sw.js', { scope: '/' });
}

// Capture beforeinstallprompt early — before Stimulus boots — so the
// pwa-install controller can pick it up on connect regardless of timing.
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  (window as Window & { __pwaPrompt?: Event }).__pwaPrompt = e;
});

// Import the correct locale early on
void initializeLocale()
  .then(() => {
    initializeGlobalListeners();

    // Due to the behaviour of the Edge browser we need to wait for 'DOM ready'
    void platformBrowser().bootstrapModule(OpenProjectModule, { applicationProviders: [provideZonelessChangeDetection()], });
  });
