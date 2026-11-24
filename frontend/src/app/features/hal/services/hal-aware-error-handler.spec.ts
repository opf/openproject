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

import { ErrorHandler, provideBrowserGlobalErrorListeners } from '@angular/core';
import type { MockInstance } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { HttpErrorResponse } from '@angular/common/http';
import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { HalAwareErrorHandler, wasReported } from './hal-aware-error-handler';

class RecordingReporter extends ErrorReporterBase {
  captureMessage = vi.fn<(msg:string) => void>();

  captureException = vi.fn<(err:unknown) => void>();
}

describe('HalAwareErrorHandler', () => {
  let reporter:RecordingReporter;
  let originalReporter:ErrorReporterBase;
  let consoleError:MockInstance<typeof console.error>;

  const halError = (status:number) => new HalError(new HttpErrorResponse({ status }), null);
  const loggedValues = () => consoleError.mock.calls.flat();

  beforeEach(() => {
    originalReporter = window.ErrorReporter;
    reporter = new RecordingReporter();
    window.ErrorReporter = reporter;
    consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => {
    window.ErrorReporter = originalReporter;
    vi.restoreAllMocks();
  });

  describe('handleError', () => {
    let handler:HalAwareErrorHandler;

    beforeEach(() => {
      TestBed.configureTestingModule({ providers: [HalAwareErrorHandler] });
      handler = TestBed.inject(HalAwareErrorHandler);
    });

    it('logs the original error', () => {
      const error = new Error('broken');

      handler.handleError(error);

      expect(loggedValues()).toContain(error);
    });

    it('reports an Error', () => {
      const error = new Error('broken');

      handler.handleError(error);

      expect(reporter.captureException).toHaveBeenCalledWith(error);
    });

    it.each([500, 503, 0])('reports a HAL error with status %i', (status) => {
      const error = halError(status);

      handler.handleError(error);

      expect(reporter.captureException).toHaveBeenCalledWith(error);
    });

    it.each([403, 404, 409, 422])('does not report a HAL error with status %i', (status) => {
      const error = halError(status);

      handler.handleError(error);

      expect(reporter.captureException).not.toHaveBeenCalled();
      expect(loggedValues()).toContain(error);
    });

    it.each([
      ['string', 'broken'],
      ['plain object', { reason: 'broken' }],
    ])('reports a thrown %s', (_kind, thrown) => {
      handler.handleError(thrown);

      expect(reporter.captureException).toHaveBeenCalledExactlyOnceWith(thrown);
      expect(reporter.captureMessage).not.toHaveBeenCalled();
    });

    it('remembers the errors it handled', () => {
      const error = new Error('broken');

      handler.handleError(error);

      expect(wasReported(error)).toBe(true);
      expect(wasReported(new Error('other'))).toBe(false);
    });

    it('reports an HTTP error response only for server and network failures', () => {
      const serverFailure = new HttpErrorResponse({ status: 502 });

      handler.handleError(new HttpErrorResponse({ status: 422 }));
      handler.handleError(serverFailure);

      expect(reporter.captureException).toHaveBeenCalledExactlyOnceWith(serverFailure);
    });
  });

  describe('with the browser global error listeners', () => {
    beforeEach(() => {
      TestBed.configureTestingModule({
        rethrowApplicationErrors: false,
        providers: [
          provideBrowserGlobalErrorListeners(),
          { provide: ErrorHandler, useClass: HalAwareErrorHandler },
        ],
      });
      TestBed.inject(ErrorHandler);
    });

    it('logs and reports an uncaught error', () => {
      const error = new Error('uncaught');

      window.dispatchEvent(new ErrorEvent('error', { error, cancelable: true }));

      expect(loggedValues()).toContain(error);
      expect(reporter.captureException).toHaveBeenCalledWith(error);
    });

    it('logs an unhandled HAL rejection without reporting a client error', () => {
      const error = halError(422);
      const promise = Promise.reject(error);
      promise.catch(() => undefined);

      window.dispatchEvent(new PromiseRejectionEvent('unhandledrejection', { promise, reason: error, cancelable: true }));

      expect(loggedValues()).toContain(error);
      expect(reporter.captureException).not.toHaveBeenCalled();
    });

    it('logs the original error while the remote reporter is not available', () => {
      reporter.captureException.mockImplementation(() => undefined);
      const error = new Error('reporter still loading');

      window.dispatchEvent(new ErrorEvent('error', { error, cancelable: true }));

      expect(loggedValues()).toContain(error);
    });
  });
});
