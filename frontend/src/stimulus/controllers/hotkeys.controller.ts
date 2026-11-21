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

import { ApplicationController, useDebounce, useMutation, useResize } from 'stimulus-use';
import { HotkeyDispatcher } from 'core-common/hotkeys/hotkey-dispatcher';

export default class HotkeysController extends ApplicationController<HTMLElement> {
  static values = {
    enabled: Boolean,
  };

  static debounces = [{ name: 'resize', wait: 200 }];

  declare readonly enabledValue:boolean;

  private dispatcher?:HotkeyDispatcher;

  private observers:(() => void)[] = [];

  initialize() {
    useDebounce(this);
    const [observeMutations] = useMutation(this, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['data-hotkey', 'data-hotkey-fallback', 'accesskey', 'data-hotkey-yielded-accesskey'],
      dispatchEvent: false,
    });
    const [observeResizes] = useResize(this, { dispatchEvent: false });
    this.observers = [observeMutations, observeResizes];
  }

  connect() {
    this.dispatcher = new HotkeyDispatcher(this.element);
    this.dispatcher.setEnabled(this.enabledValue);
    this.dispatcher.start();
    this.observers.forEach((observe) => observe());
  }

  disconnect() {
    this.dispatcher?.stop();
    this.dispatcher = undefined;
  }

  mutate() {
    this.dispatcher?.reconcile();
  }

  resize() {
    this.dispatcher?.reconcile();
  }

  enabledValueChanged() {
    this.dispatcher?.setEnabled(this.enabledValue);
  }
}
