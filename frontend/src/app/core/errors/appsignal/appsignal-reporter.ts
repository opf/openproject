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

import { debugLog } from 'core-app/shared/helpers/debug_output';
import { ErrorReporterBase, ErrorTags, MessageSeverity, toError } from 'core-app/core/errors/error-reporter-base';
import type { Appsignal } from './appsignal-dependency';
import { Span } from '@appsignal/javascript';
import { getMetaElement } from 'core-app/core/setup/globals/global-helpers';

export class AppsignalReporter extends ErrorReporterBase {
  private client:Appsignal;

  public readonly loaded:Promise<void>;

  public captureMessage(msg:string, severity:MessageSeverity = 'info'):void {
    console.warn('Logging message %O with severity %O', msg, severity);
  }

  public captureException(err:unknown):void {
    if (!this.client) {
      debugLog('Appsignal is not yet loaded, ignoring error %O', err);
      return;
    }

    void this.send(toError(err));
  }

  constructor() {
    super();
    const element = getMetaElement('openproject_appsignal')!;
    this.loaded = this.loadAppsignal(element)
      .catch((error:unknown) => debugLog('Appsignal failed to load %O', error));
  }

  private loadAppsignal(element:HTMLElement):Promise<void> {
    const key = element.dataset.pushKey || '';
    const revision = element.dataset.version || '';

    return import('./appsignal-dependency').then((imported) => {
      this.client = new imported.Appsignal({
        namespace: 'frontend',
        key,
        revision,
        ignoreErrors: [
          /getComputedStyle/,
          /Loading chunk/,
        ],
      });

      this.client.use(imported.networkPlugin());
    });
  }

  // The SDK serializes the span right after calling back, so the tags are
  // resolved first.
  private async send(error:Error):Promise<void> {
    try {
      const tags:ErrorTags = {
        locale: (window.I18n as { locale:string }).locale,
        domain: window.location.hostname,
        url_path: window.location.pathname,
        url_query: window.location.search,
        ...await this.contextTags(),
      };

      await this.client.sendError(error, (span:Span) => span.setTags(tags));
    } catch (sendError) {
      debugLog('Appsignal failed to send %O: %O', error, sendError);
    }
  }
}
