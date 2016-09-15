//-- copyright
// OpenspentTime is a spentTime management system.
// Copyright (C) 2012-2015 the OpenspentTime Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenspentTime is a fork of ChilispentTime, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChilispentTime Team
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

class SpentTimeTooltipController extends TableTooltipController {
  constructor($scope) {
    super($scope);

    $scope.showSpentTimePath =
      URI.expand('projects/{identifier}/time_entries', $scope.workPackage.project).valueOf();
    $scope.addTimeEntryPath =
      URI.expand('work_packages/{id}/time_entries/new', $scope.workPackage).valueOf();
  }
}

function spentTimeTooltipService(opTooltip) {
  return opTooltip({
    templateUrl: '/components/wp-table-tooltips/spent-time-tooltip/spent-time-tooltip.service.html',
    controller: SpentTimeTooltipController
  });
}

wpDirectivesModule.factory('spentTimeTooltip', spentTimeTooltipService);
