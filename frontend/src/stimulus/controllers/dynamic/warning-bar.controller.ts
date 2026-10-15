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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';

export default class WarningBarController extends Controller<HTMLElement> {
  private resizeObserver:ResizeObserver;

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.publishHeight());
    this.resizeObserver.observe(this.element);
  }

  disconnect() {
    this.resizeObserver.disconnect();
    document.documentElement.style.removeProperty('--warning-bar-height');
  }

  private publishHeight() {
    document.documentElement.style.setProperty('--warning-bar-height', `${this.element.offsetHeight}px`);
  }
}
