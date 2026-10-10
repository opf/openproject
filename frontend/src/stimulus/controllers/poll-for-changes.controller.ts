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

import { ApplicationController } from 'stimulus-use';
import { renderStreamMessage, session } from '@hotwired/turbo';

// Turbo remembers the ids of the requests this tab sent and ignores its own `refresh`
// broadcasts the same way (Session#refresh). `recentRequests` is not part of Turbo's typings.
function sentByThisTab(requestId:string|undefined):boolean {
  const { recentRequests } = session as unknown as { recentRequests?:{ has(id:string):boolean } };
  return !!requestId && !!recentRequests?.has(requestId);
}

export default class PollForChangesController extends ApplicationController {
  static values = {
    url: String,
    interval: Number,
    reference: String,
    continuous: Boolean,
    event: String,
  };

  static targets = ['reference'];

  declare referenceTarget:HTMLElement;
  declare readonly hasReferenceTarget:boolean;

  declare referenceValue:string;
  declare urlValue:string;
  declare intervalValue:number;
  declare continuousValue:boolean;
  declare eventValue:string;

  private interval:number;

  connect() {
    super.connect();

    // When `eventValue` is provided, a live update is requested instead of polling.
    if (this.eventValue) {
      document.addEventListener(this.eventValue, this.handleChange);
    } else if (this.intervalValue !== 0) {
      this.interval = window.setInterval(() => {
        void this.triggerTurboStream();
      }, this.intervalValue || 10_000);
    }
  }

  disconnect() {
    super.disconnect();
    this.stop();
  }

  buildReference():string {
    if (this.hasReferenceTarget) {
      return this.referenceTarget.dataset.referenceValue!;
    }

    return this.referenceValue;
  }

  triggerTurboStream() {
    const url = new URL(this.urlValue, window.location.origin);
    const ref = this.buildReference();
    if (ref) url.searchParams.set('reference', ref);

    void fetch(url.toString())
      .then(async (r) => {
      if (r.status === 200) {
        if (!this.continuousValue) {
          this.stop();
        }

        const html = await r.text();
        renderStreamMessage(html);
      }
    });
  }

  private handleChange = (event:Event) => {
    if (!sentByThisTab((event as CustomEvent<{ requestId?:string }|null>).detail?.requestId)) {
      this.triggerTurboStream();
    }
  };

  private stop() {
    clearInterval(this.interval);
    if (this.eventValue) {
      document.removeEventListener(this.eventValue, this.handleChange);
    }
  }
}
