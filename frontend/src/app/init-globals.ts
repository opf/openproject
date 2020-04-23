// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {whenDebugging} from 'core-app/helpers/debug_output';
import {enableReactiveStatesLogging} from "reactivestates";
import 'hammerjs';

// Ensure we set the correct dynamic frontend path
// based on the RAILS_RELATIVE_URL_ROOT setting
// https://webpack.js.org/guides/public-path/
const ASSET_BASE_PATH = '/assets/frontend/';

// Global scripts previously part of the application.js
// Avoid require.context since that crashes angular regularly
require('./globals/augmenting/modal-wrapper.augment.service');
require('./globals/dynamic-bootstrapper');
require('./globals/global-listeners');
require('./globals/openproject');
require('./globals/tree-menu');

// Sets the relative base path
window.appBasePath = jQuery('meta[name=app_base_path]').attr('content') || '';

// Ensure to set the asset base for dynamic code loading
// https://webpack.js.org/guides/public-path/
__webpack_public_path__ = window.appBasePath + ASSET_BASE_PATH;

const meta = jQuery('meta[name=openproject_initializer]');
I18n.locale = meta.data('defaultLocale');
I18n.locale = meta.data('locale');
I18n.firstDayOfWeek = parseInt(meta.data('firstDayOfWeek'), 10);

// Enable debug logging for reactive states
whenDebugging(() => {
  (window as any).enableReactiveStatesLogging = () => enableReactiveStatesLogging(true);
  (window as any).disableReactiveStatesLogging = () => enableReactiveStatesLogging(false);
});

