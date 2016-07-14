//-- copyright
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
//++

// 'Global' dependencies
//
// dependencies required by classic (Rails) and Angular application.

// NOTE: currently needed for PhantomJS to support Webpack's style-loader.
// See: https://github.com/webpack/style-loader/issues/31
require('polyfill-function-prototype-bind');
require('lodash');

require('expose?$!expose?jQuery!jquery');
require('expose?angular!angular');

require('jquery-migrate');
require('jquery.caret');
require('at.js/css/jquery.atwho.min.css');
require('at.js/js/jquery.atwho.min.js');

require('jquery-ui/ui/core.js');
require('jquery-ui/ui/datepicker.js');
require('jquery-ui/ui/dialog.js');
require('jquery-ui/ui/i18n/datepicker-en-GB.js');
require('jquery-ui/ui/i18n/datepicker-de.js');
require('jquery-ui/themes/base/core.css');
require('jquery-ui/themes/base/datepicker.css');
// TODO: move require to backlogs plugin
require('jquery-ui/themes/base/dialog.css');
require('./misc/datepicker-defaults');

require('expose?dragula!dragula');

// TODO extract
require('expose?moment!moment');
require('moment/locale/en-gb.js');
require('moment/locale/de.js');

require('moment-timezone');


require('select2/select2.js');
require('select2/select2.css');

// ****
// Foundation for apps js part
// We should not load the pre-built js for foundation-apps meaning we cannot state
//
//  require('foundation-apps/dist/js/foundation-apps.js');
//
// We therefore have to require all of foundation's parts on our own.

// js for the various parts of foundation-apps
var requireComponents = require.context('foundation-apps/js/angular/components', true, /\.js$/);
requireComponents.keys().forEach(requireComponents);
var requireServices = require.context('foundation-apps/js/angular/services', true, /\.js$/);
requireServices.keys().forEach(requireServices);

// js for the foundation initialization
require('foundation-apps/js/angular/foundation.js');

// all of foundation's templates
require('foundation-apps/dist/js/foundation-apps-templates.js');

// foundation's css
require('foundation-apps/dist/css/foundation-apps.css');

