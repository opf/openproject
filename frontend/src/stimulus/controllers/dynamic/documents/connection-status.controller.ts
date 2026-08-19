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

type ConnectionState = 'live' | 'offline' | 'recovered';

export default class ConnectionStatusController extends Controller {
  static targets = ['live', 'offline', 'recovered'];

  declare readonly offlineTarget:HTMLElement;
  declare readonly recoveredTarget:HTMLElement;
  declare readonly liveTargets:HTMLElement[];

  private recoveryTimeout:ReturnType<typeof setTimeout>|null = null;

  showOffline():void {
    this.clearRecoveryTimeout();
    this.activateState('offline');
  }

  showRecovered():void {
    this.clearRecoveryTimeout();
    this.activateState('recovered');

    this.recoveryTimeout = setTimeout(() => this.activateState('live'), 5000);
  }

  disconnect():void {
    this.clearRecoveryTimeout();
  }

  private activateState(state:ConnectionState):void {
    this.offlineTarget.hidden = state !== 'offline';
    this.recoveredTarget.hidden = state !== 'recovered';
    this.liveTargets.forEach((el) => { el.hidden = state !== 'live'; });
  }

  private clearRecoveryTimeout():void {
    if (this.recoveryTimeout !== null) {
      clearTimeout(this.recoveryTimeout);
      this.recoveryTimeout = null;
    }
  }
}
