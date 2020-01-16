// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Scope} from "@sentry/hub";
import {Severity} from "@sentry/types";
import {Event as SentryEvent} from "@sentry/types";
import {environment} from "../../environments/environment";

export type ScopeCallback = (scope:Scope) => void;


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

export type MessageSeverity = 'fatal'|'error'|'warning'|'log'|'info'|'debug';

interface QueuedMessage {
  type:'captureMessage'|'captureException';
  args:any[];
}

export class SentryReporter implements ErrorReporter {

  private contextCallbacks:ScopeCallback[] = [];

  private messageStack:QueuedMessage[] = [];

  private readonly sentryConfigured:boolean = true;

  private client:any;

  constructor() {
    const sentryElement = document.querySelector('meta[name=openproject_sentry]') as HTMLElement|null;
    if (sentryElement) {
      import('@sentry/browser').then((Sentry) => {
        Sentry.init({
          dsn: sentryElement.dataset.dsn!,
          debug: !environment.production,
          ignoreErrors: [
            // Transition movements,
            'The transition has been superseded by a different transition',
            // Uncaught promise rejections
            'Uncaught (in promise)'
          ],
          beforeSend: (event) => this.filterEvent(event)
        });

        this.sentryLoaded(Sentry);
      });
    } else {
      this.sentryConfigured = false;
      this.messageStack = [];
    }
  }

  public sentryLoaded(client:any) {
    this.client = client;
    client.configureScope(this.setupContext.bind(this));

    // Send all messages from before sentry got loaded
    this.messageStack.forEach((item) => {
      this[item.type].bind(this).apply(item.args);
    });
  }

  public captureMessage(msg:string, severity:MessageSeverity = 'info') {
    if (!this.client) {
      return this.handleOfflineMessage('captureMessage', Array.from(arguments));
    }

    this.client.withScope((scope:Scope) => {
      this.setupContext(scope);
      this.client.captureMessage(msg, Severity.fromString(severity));
    });
  }

  public captureException(err:Error|string) {
    if (!this.client || !err) {
      this.handleOfflineMessage('captureException', Array.from(arguments));
      throw err;
    }

    if (typeof err === 'string') {
      return this.captureMessage(err, 'error');
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
      callbacks.forEach(cb => this.client.configureScope(cb));
    }
  }

  /**
   * Remember a message or error for later handling
   * @param type
   * @param args
   */
  private handleOfflineMessage(type:'captureMessage'|'captureException', args:any[]) {
    if (this.sentryConfigured) {
      this.messageStack.push({ type, args });
    } else {
      console.log("[ErrorReporter] Would queue sentry message %O %O, but is not configured.", type, args);
    }
  }

  /**
   * Set up the current scope for the event to be sent.
   * @param scope
   */
  private setupContext(scope:Scope) {
    scope.setTag('locale', I18n.locale);
    scope.setTag('domain', window.location.hostname);
    scope.setTag('url_path', window.location.pathname);
    scope.setExtra('url_query', window.location.search);

    /** Execute callbacks */
    this.contextCallbacks.forEach(cb => cb(scope));
  }

  /**
   * Filters the event content's or removes
   * it from being sent.
   *
   * @param event
   */
  private filterEvent(event:SentryEvent):SentryEvent|null {
    const unsupportedBrowser = document.body.classList.contains('-unsupported-browser');
    if (unsupportedBrowser) {
      console.warn("Browser is not supported, skipping sentry reporting completely.")
      return null;
    }

    return event;
  }
}