//-- copyright
// Openversion is a version management system.
// Copyright (C) 2012-2015 the Openversion Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// Openversion is a fork of Chiliversion, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the Chiliversion Team
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

import {wpDirectivesModule} from '../../../angular-modules';
import {TableTooltipController} from '../table-tooltip.controller';

class VersionTooltipController extends TableTooltipController {
  protected projectUrls = {
    versionInfoPath: 'projects/{identifier}/settings/versions',
    versionAddPath: 'projects/{identifier}/versions/new'
  };
}

function versionTooltipService(opTooltip) {
  return opTooltip({
    templateUrl: '/components/wp-table-tooltips/version-tooltip/version-tooltip.service.html',
    controller: VersionTooltipController
  });
}

wpDirectivesModule.factory('versionTooltip', versionTooltipService);
