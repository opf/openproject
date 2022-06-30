// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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

import {
  Event as SentryEvent,
  Hub,
  Scope,
  Severity,
} from '@sentry/types';
import { environment } from '../../../../environments/environment';
import { EventHint } from '@sentry/angular';
import { HttpErrorResponse } from '@angular/common/http';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { HalError } from 'core-app/features/hal/services/hal-error';
import {
  ErrorReporterBase,
  ErrorTags,
  MessageSeverity,
} from 'core-app/core/errors/error-reporter-base';

export class SentryReporter extends ErrorReporterBase {
  private client:Hub;

  constructor() {
    super();
    const sentryElement = document.querySelector('meta[name=openproject_sentry]') as HTMLElement;
    this.loadSentry(sentryElement);
  }

  private loadSentry(sentryElement:HTMLElement) {
    const dsn = sentryElement.dataset.dsn || '';
    const version = sentryElement.dataset.version || 'unknown';
    const traceFactor = parseFloat(sentryElement.dataset.tracingFactor || '0.0');

    void import('./sentry-dependency').then((imported) => {
      const sentry = imported.Sentry;
      sentry.init({
        dsn,
        debug: !environment.production,
        release: version,
        environment: environment.production ? 'production' : 'development',

        // Integrations
        integrations: [new imported.Integrations.BrowserTracing()],

        tracesSampler: (samplingContext) => {
          switch (samplingContext.transactionContext.op) {
            case 'op':
            case 'navigation':
              // Trace 1% of page loads and navigation events
              return Math.min(0.01 * traceFactor, 1.0);
            default:
              // Trace 0.1% of requests
              return Math.min(0.001 * traceFactor, 1.0);
          }
        },

        ignoreErrors: [
          // Transition movements,
          'The transition has been superseded by a different transition',
          // Uncaught promise rejections
          'Uncaught (in promise)',
          // Non-errors caught for hal resources
          'Non-Error exception captured with keys: $embedded, $halType, $links, $loaded',

        ],
        beforeSend: (event, hint) => SentryReporter.filterEvent(event, hint),
      });

      this.sentryLoaded(sentry as unknown as Hub);
    });
  }

  public sentryLoaded(client:Hub):void {
    this.client = client;
    client.configureScope(this.setupContext.bind(this));
  }

  public captureMessage(msg:string, severity:MessageSeverity = 'info'):void {
    if (!this.client) {
      debugLog('Sentry is not yet loaded, ignoring %O', msg);
      return;
    }

    this.client.withScope((scope:Scope) => {
      void this
        .setupContext(scope)
        .then(() => this.client.captureMessage(msg, Severity.fromString(severity)));
    });
  }

  public captureException(err:Error|string):void {
    if (!this.client || !err) {
      debugLog('Sentry is not yet loaded, ignoring error %O', err);
    }

    if (typeof err === 'string') {
      this.captureMessage(err, 'error');
      return;
    }

    this.client.withScope((scope:Scope) => {
      void this
        .setupContext(scope)
        .then(() => this.client.captureException(err));
    });
  }

  /**
   * Set up the current scope for the event to be sent.
   * @param scope
   */
  private async setupContext(scope:Scope) {
    scope.setTag('code_origin', 'frontend');
    scope.setTag('locale', window.I18n.locale);
    scope.setTag('domain', window.location.hostname);
    scope.setTag('url_path', window.location.pathname);
    scope.setExtra('url_query', window.location.search);

    /** Execute callbacks */
    const results = await this.hookPromises();
    results.forEach((tags:ErrorTags) => {
      Object.keys(tags).forEach((key) => {
        if (key === 'user') {
          scope.setUser({ id: tags[key] });
        } else {
          scope.setTag(key, tags[key]);
        }
      });
    });
  }

  /**
   * Filters the event content's or removes
   * it from being sent.
   *
   * @param event
   * @param hint
   */
  private static filterEvent(event:SentryEvent, hint:EventHint|undefined):SentryEvent|null {
    // avoid duplicate requests on thrown angular errors, they
    // are handled by the hal error handler
    // https://github.com/getsentry/sentry-javascript/issues/2532#issuecomment-875428325
    const exception = hint?.originalException;
    if (exception instanceof HttpErrorResponse) {
      return SentryReporter.filterHttpError(event, exception);
    }

    if (exception instanceof HalError) {
      return SentryReporter.filterHttpError(event, exception.httpError);
    }

    const unsupportedBrowser = document.body.classList.contains('-unsupported-browser');
    if (unsupportedBrowser) {
      console.warn('Browser is not supported, skipping sentry reporting completely.');
      return null;
    }

    return event;
  }

  /**
   * Filter http errors before sending to sentry. For now, we only want 5xx+ errors
   * @param event
   * @param exception
   * @private
   */
  private static filterHttpError(event:SentryEvent, exception:HttpErrorResponse):SentryEvent|null {
    if (exception.status >= 500) {
      return event;
    }

    return null;
  }
}
