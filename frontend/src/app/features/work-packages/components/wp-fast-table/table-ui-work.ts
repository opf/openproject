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

import { DestroyRef } from '@angular/core';
import { onDestroySafely, runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';

export class TableUiWork {
  private readonly frames = new Set<number>();

  private readonly tasks = new Set<number>();

  constructor(private readonly destroyRef:DestroyRef,
    private readonly alive:() => boolean = () => !destroyRef.destroyed) {
    onDestroySafely(destroyRef, () => this.cancel());
  }

  frame(callback:() => void):void {
    if (!this.alive()) return;
    const id = window.requestAnimationFrame(() => {
      this.frames.delete(id);
      if (this.alive()) callback();
    });
    this.frames.add(id);
  }

  task(callback:() => void):void {
    if (!this.alive()) return;
    const id = window.setTimeout(() => {
      this.tasks.delete(id);
      if (this.alive()) callback();
    });
    this.tasks.add(id);
  }

  cancel():void {
    this.frames.forEach((id) => runCleanup(() => window.cancelAnimationFrame(id)));
    this.tasks.forEach((id) => runCleanup(() => window.clearTimeout(id)));
    this.frames.clear();
    this.tasks.clear();
  }
}
