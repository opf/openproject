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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { debugLog } from 'core-app/shared/helpers/debug_output';
import { ErrorReporterBase, ErrorTags, MessageSeverity } from 'core-app/core/errors/error-reporter-base';
import type { Appsignal, Span } from './appsignal-dependency';

export class AppsignalReporter extends ErrorReporterBase {
  private client:Appsignal;

  public captureMessage(msg:string, severity:MessageSeverity = 'info'):void {
    console.warn('Logging message %O with severity %O', msg, severity);
  }

  public captureException(err:Error|string):void {
    if (!this.client || !err) {
      debugLog('Appsignal is not yet loaded, ignoring error %O', err);
      return;
    }

    const error = (typeof err === 'string') ? new Error(err) : err;
    void this.client.sendError(error, (span) => this.setupContext(span));
  }

  constructor() {
    super();
    const element = document.querySelector('meta[name=openproject_appsignal]') as HTMLElement;
    this.loadAppsignal(element);
  }

  private loadAppsignal(element:HTMLElement) {
    const key = element.dataset.pushKey || '';
    const revision = element.dataset.version || '';

    void import('./appsignal-dependency').then((imported) => {
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

  /**
   * @param span The appsignal span to send with
   */
  private async setupContext(span:Span):Promise<Span> {
    /** Execute callbacks */
    const results = await this.hookPromises();

    let tags = {
      locale: (window.I18n as { locale:string }).locale,
      domain: window.location.hostname,
      url_path: window.location.pathname,
      url_query: window.location.search,
    };

    results.forEach((added:ErrorTags) => {
      tags = { ...tags, ...added };
    });

    span.setTags(tags);

    return span;
  }
}
