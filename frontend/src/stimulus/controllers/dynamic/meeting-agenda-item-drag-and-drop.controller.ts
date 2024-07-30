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

import * as Turbo from '@hotwired/turbo';
import { Controller } from '@hotwired/stimulus';
import { Drake } from 'dragula';
import { debugLog } from 'core-app/shared/helpers/debug_output';

export default class extends Controller {
  drake:Drake|undefined;

  autoScroll() {
    // options copied from generic-drag-and-drop.controller for consistency
    void window.OpenProject.getPluginContext().then((pluginContext) => {
      // eslint-disable-next-line no-new
      new pluginContext.classes.DomAutoscrollService(
        [
          document.getElementById('content-body') as HTMLElement,
        ],
        {
          margin: 25,
          maxSpeed: 10,
          scrollWhenOutside: true,
          autoScroll: () => this.drake?.dragging,
        },
      );
    });
  }

  connect() {
    this.drake = dragula(
      [this.containerTarget],
      { moves: (_el, _source, handle, _sibling) => !!handle?.classList.contains('octicon-grabber') },
    )
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      .on('drop', this.drop.bind(this));

    this.autoScroll();
  }

  get containerTarget():HTMLElement {
    const targetTag = this.data.get('target-tag');
    return this.element.querySelector(targetTag || 'ul') as HTMLElement;
  }

  async drop(el:Element, _target:Element|null, _source:Element|null, _sibling:Element|null) {
    const id = el.getAttribute('data-id');
    const url = el.getAttribute('data-drop-url');
    const data = new FormData();
    const newIndex = Array.from(this.containerTarget.children).indexOf(el);

    if (id && url) {
      data.append('position', (newIndex + 1).toString());

      const response = await fetch(url, {
        method: 'PUT',
        body: data,
        headers: {
          'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
          Accept: 'text/vnd.turbo-stream.html',
        },
        credentials: 'same-origin',
      });

      if (!response.ok) {
        debugLog('Failed to sort item');
      } else {
        const text = await response.text();
        Turbo.renderStreamMessage(text);
      }
    }

    if (this.drake) {
      this.drake.cancel(true); // necessary to prevent "copying" behaviour
    }
  }

  disconnect() {
    if (this.drake) {
      this.drake.destroy();
    }
  }
}
