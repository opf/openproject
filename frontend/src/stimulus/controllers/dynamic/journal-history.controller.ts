/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';

export default class JournalHistoryController extends Controller {
  static targets = [
    'fromVersion',
    'toVersion',
  ];

  declare readonly fromVersionTargets:HTMLInputElement[];

  declare readonly toVersionTargets:HTMLInputElement[];

  // Automatically selects the to version when the from version is selected.
  // The version chosen is the one above the selected version.
  selectToVersion(event:Event) {
    const clickedVersion = (event.target || this.fromVersionTargets[0]) as HTMLInputElement;

    const index = this.fromVersionTargets.indexOf(clickedVersion);

    this.toVersionTargets[index].checked = true;
  }

  // Automatically corrects the from version when the to version is selected.
  // In case from and to version are the same after the selection, the from version is corrected to the version above.
  // Otherwise, nothing is changed.
  selectFromVersion(event:Event) {
    const clickedVersion = (event.target || this.toVersionTargets[0]) as HTMLInputElement;

    const index = this.toVersionTargets.indexOf(clickedVersion);

    if (this.fromVersionTargets[index + 1].checked) {
      this.fromVersionTargets[index].checked = true;
    }
  }
}
