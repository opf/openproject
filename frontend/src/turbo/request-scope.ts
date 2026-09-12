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

// Counts the in-flight operations of one consumer (a controller root, a
// dialog trigger) so it can block re-entrant work and reflect busy state onto
// whatever DOM it currently owns. Knows nothing of DOM or Angular: consumers
// construct it synchronously, keep it across reconnects and subscribe to
// project its state.
export class TurboRequestScope {
  #pending = 0;

  #listeners = new Set<() => void>();

  get busy():boolean {
    return this.#pending > 0;
  }

  subscribe(listener:() => void):() => void {
    this.#listeners.add(listener);

    return () => {
      this.#listeners.delete(listener);
    };
  }

  async track<T>(operation:() => Promise<T>):Promise<T> {
    this.#enter();
    try {
      return await operation();
    } finally {
      this.#leave();
    }
  }

  #enter():void {
    this.#pending += 1;
    if (this.#pending === 1) {
      this.#notify();
    }
  }

  #leave():void {
    this.#pending -= 1;
    if (this.#pending === 0) {
      this.#notify();
    }
  }

  #notify():void {
    this.#listeners.forEach((listener) => listener());
  }
}
