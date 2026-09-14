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

import { Controller } from '@hotwired/stimulus';
import { FrameElement } from '@hotwired/turbo';

export default class JobStatusPollingController extends Controller<HTMLElement> {
  static targets = ['finished', 'download', 'redirect', 'indicator', 'frame'];
  static values = { backOnClose: { type: Boolean, default: false } };

  declare readonly backOnCloseValue:boolean;
  declare readonly indicatorTarget:HTMLElement;
  declare readonly frameTarget:FrameElement;

  interval:ReturnType<typeof setInterval>;
  userInteraction = false;

  connect() {
    this.interval = setInterval(() => this.frameTarget.reload(), 2000);
  }

  disconnect() {
    this.stopPolling();
    if (this.backOnCloseValue && !this.userInteraction) {
      window.history.back();
    }
  }

  finishedTargetConnected() {
    this.stopPolling();
    this.hideProgressIndicator();
  }

  stopPolling() {
    clearInterval(this.interval);
  }

  hideProgressIndicator() {
    this.indicatorTarget.remove();
  }

  downloadTargetConnected(element:HTMLLinkElement) {
    setTimeout(() => element.click(), 50);
  }

  redirectClick(event:PointerEvent) {
    event.preventDefault();
    this.followLink(event.target as HTMLLinkElement);
  }

  redirectTargetConnected(element:HTMLLinkElement) {
    setTimeout(() => {
      this.followLink(element);
    }, 2000);
  }

  followLink(element:HTMLLinkElement) {
    this.userInteraction = true;
    window.location.href = element.href;
  }
}
