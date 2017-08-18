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

import {wpControllersModule} from '../../../angular-modules';
import {WorkPackageTableTimelineService} from '../../wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTableColumnsService} from '../../wp-fast-table/state/wp-table-columns.service';

function TimelinesModalController(this:any,
                                  timelinesModal:any,
                                  $scope:any,
                                  wpTableTimeline:WorkPackageTableTimelineService,
                                  wpTableColumns:WorkPackageTableColumnsService,
                                  I18n:op.I18n) {
  this.name = 'Timelines';
  this.closeMe = timelinesModal.deactivate;

  $scope.text = {
    apply: I18n.t('js.modals.button_apply'),
    cancel: I18n.t('js.modals.button_cancel'),
    close: I18n.t('js.close_popup_title'),
    title: I18n.t('js.timelines.gantt_chart'),
    labels: {
      description: I18n.t('js.timelines.labels.description'),
      bar: I18n.t('js.timelines.labels.bar'),
      none: I18n.t('js.timelines.filter.noneSelection'),
      left: I18n.t('js.timelines.labels.left'),
      right: I18n.t('js.timelines.labels.right'),
      farRight: I18n.t('js.timelines.labels.farRight')
    }
  };

  // Current label models
  const labels = wpTableTimeline.labels;
  $scope.labels = _.clone(labels);

  // Available labels
  const availableColumns = wpTableColumns
    .allPropertyColumns
    .sort((a, b) => a.name.localeCompare(b.name));

  $scope.availableAttributes = [{ id: '', name: $scope.text.labels.none }].concat(availableColumns);

  // Save
  $scope.updateLabels = () => {
    wpTableTimeline.updateLabels($scope.labels);
    timelinesModal.deactivate();
  };
}

wpControllersModule.controller('TimelinesModalController', TimelinesModalController);
