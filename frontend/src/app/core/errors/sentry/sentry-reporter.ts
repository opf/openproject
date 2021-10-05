// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

export type ScopeCallback = (scope:Scope) => void;
export type MessageSeverity = 'fatal'|'error'|'warning'|'log'|'info'|'debug';

export interface CaptureInterface {
  /** Capture a message */
  captureMessage(msg:string, level?:MessageSeverity):void;

  /** Capture an exception(!) only */
  captureException(err:Error):void;
}

export interface SentryClient extends CaptureInterface {
  configureScope(scope:ScopeCallback):void;

  withScope(scope:ScopeCallback):void;
}

export interface ErrorReporter extends CaptureInterface {
  /** Register a context callback handler */
  addContext(...callbacks:ScopeCallback[]):void;
}

interface QueuedMessage {
  type:'captureMessage'|'captureException';
  args:unknown[];
}

export class SentryReporter implements ErrorReporter {
  private contextCallbacks:ScopeCallback[] = [];

  private messageStack:QueuedMessage[] = [];

  private readonly sentryConfigured:boolean = true;

  private client:Hub;

  constructor() {
    const sentryElement = document.querySelector('meta[name=openproject_sentry]') as HTMLElement;
    if (sentryElement !== null) {
      this.loadSentry(sentryElement);
    } else {
      this.sentryConfigured = false;
      this.messageStack = [];
    }
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

    // Send all messages from before sentry got loaded
    this.messageStack.forEach((item) => {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-member-access
      this[item.type].bind(this).apply(item.args);
    });
  }

  public captureMessage(msg:string, severity:MessageSeverity = 'info'):void {
    if (!this.client) {
      this.handleOfflineMessage('captureMessage', [msg, severity]);
      return;
    }

    this.client.withScope((scope:Scope) => {
      this.setupContext(scope);
      this.client.captureMessage(msg, Severity.fromString(severity));
    });
  }

  public captureException(err:Error|string):void {
    if (!this.client || !err) {
      this.handleOfflineMessage('captureException', [err]);
      throw (err as Error);
    }

    if (typeof err === 'string') {
      this.captureMessage(err, 'error');
      return;
    }

    this.client.withScope((scope:Scope) => {
      this.setupContext(scope);
      this.client.captureException(err);
    });
  }

  public addContext(...callbacks:ScopeCallback[]):void {
    this.contextCallbacks.push(...callbacks);

    if (this.client) {
      /** Add to global context as well */
      callbacks.forEach((cb) => this.client.configureScope(cb));
    }
  }

  /**
   * Remember a message or error for later handling
   * @param type
   * @param args
   */
  private handleOfflineMessage(type:'captureMessage'|'captureException', args:unknown[]) {
    if (this.sentryConfigured) {
      this.messageStack.push({ type, args });
    } else {
      debugLog('[ErrorReporter] Would queue sentry message %O %O, but is not configured.', type, args);
    }
  }

  /**
   * Set up the current scope for the event to be sent.
   * @param scope
   */
  private setupContext(scope:Scope) {
    scope.setTag('code_origin', 'frontend');
    scope.setTag('locale', window.I18n.locale);
    scope.setTag('domain', window.location.hostname);
    scope.setTag('url_path', window.location.pathname);
    scope.setExtra('url_query', window.location.search);

    /** Execute callbacks */
    this.contextCallbacks.forEach((cb) => cb(scope));
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
