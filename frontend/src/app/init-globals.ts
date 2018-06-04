// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {getUIRouter} from '@uirouter/angular-hybrid';
import {ExpressionService} from 'core-app/modules/common/xss/expression.service';

// Run the browser detection
require('expose-loader?bowser!bowser');

// Styles for global dependencies
require('at.js/dist/css/jquery.atwho.min.css');
require('../../vendor/select2/select2.css');
require('ui-select/dist/select.min.css');
require('jquery-ui/themes/base/core.css');
require('jquery-ui/themes/base/datepicker.css');
require('jquery-ui/themes/base/dialog.css');

// Global scripts previously part of the application.js
var requireGlobals = require.context('./globals/', true, /\.ts$/);
requireGlobals.keys().forEach(requireGlobals);

// load I18n, depending on the html element having a 'lang' attribute
var documentLang = (angular.element('html').attr('lang') || 'en').toLowerCase();
try {
  require('angular-i18n/angular-locale_' + documentLang + '.js');
}
catch(e) {
  require('angular-i18n/angular-locale_en.js');
}

import {whenDebugging} from 'core-app/helpers/debug_output';
import {enableReactiveStatesLogging} from "reactivestates";
window.appBasePath = jQuery('meta[name=app_base_path]').attr('content') || '';

const meta = jQuery('meta[name=openproject_initializer]');
I18n.locale = meta.data('defaultLocale');
I18n.locale = meta.data('locale');

require('./layout');


var requireComponent = require.context('./components/', true, /^((?!\.(test|spec)).)*\.(js|ts|html)$/);
requireComponent.keys().forEach(requireComponent);

// Enable debug logging for reactive states
whenDebugging(enableReactiveStatesLogging);

