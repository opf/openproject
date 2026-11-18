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

import { Subject, throwError } from 'rxjs';
import { LatestOnly } from 'core-app/features/work-packages/routing/wp-view-base/latest-only';

describe('LatestOnly', () => {
  let latest:LatestOnly;
  let applied:string[];
  const apply = (result:string) => applied.push(result);
  const respond = (request:Subject<string>, result:string) => {
    request.next(result);
    request.complete();
  };

  beforeEach(() => {
    latest = new LatestOnly();
    applied = [];
  });

  it('applies the response of a single request', async () => {
    const request = new Subject<string>();
    const done = latest.apply(request, apply);

    respond(request, 'only');
    await done;

    expect(applied).toEqual(['only']);
  });

  it('applies the response of the latest request only', async () => {
    const first = new Subject<string>();
    const second = new Subject<string>();
    const a = latest.apply(first, apply);
    const b = latest.apply(second, apply);

    respond(second, 'new');
    respond(first, 'old');
    await Promise.all([a, b]);

    expect(applied).toEqual(['new']);
  });

  it('cancels a request as soon as a newer one starts', () => {
    const first = new Subject<string>();
    void latest.apply(first, apply);
    expect(first.observed).toBe(true);

    void latest.apply(new Subject<string>(), apply);

    expect(first.observed).toBe(false);
    expect(applied).toEqual([]);
  });

  describe('for a request that was superseded', () => {
    let second:Subject<string>;
    let outcome:string;

    beforeEach(() => {
      outcome = 'pending';
      const superseded = latest.apply(new Subject<string>(), apply);
      superseded.then(() => { outcome = 'resolved'; }, () => { outcome = 'rejected'; });
      second = new Subject<string>();
      void latest.apply(second, apply).catch(() => undefined);
    });

    it('stays pending while its successor is running', async () => {
      await new Promise((resolve) => { setTimeout(resolve); });

      expect(outcome).toBe('pending');
    });

    it('resolves once its successor was applied', async () => {
      respond(second, 'new');

      await vi.waitFor(() => expect(outcome).toBe('resolved'));
      expect(applied).toEqual(['new']);
    });

    it('rejects when its successor fails', async () => {
      second.error(new Error('failed'));

      await vi.waitFor(() => expect(outcome).toBe('rejected'));
    });
  });

  it('announces each applied result after applying it', () => {
    const announced:unknown[] = [];
    latest.applied$.subscribe((result) => announced.push([result, [...applied]]));
    const request = new Subject<string>();
    void latest.apply(request, apply);

    respond(request, 'only');

    expect(announced).toEqual([['only', ['only']]]);
  });

  it('rejects when the latest request fails', async () => {
    const failure = new Error('failed');

    await expect(latest.apply(throwError(() => failure), apply)).rejects.toBe(failure);
    expect(applied).toEqual([]);
  });

  it('rejects with an error carrying the cause when the request fails with something else', async () => {
    const failure = { errorIdentifier: 'urn:openproject-org:api:v3:errors:NotFound' };

    const rejection = await latest.apply(throwError(() => failure), apply).catch((error:unknown) => error);

    expect(rejection).toBeInstanceOf(Error);
    expect((rejection as Error).cause).toBe(failure);
  });

  it('keeps applying later requests after one failed', async () => {
    await latest.apply(throwError(() => new Error('failed')), apply).catch(() => undefined);
    const request = new Subject<string>();
    const done = latest.apply(request, apply);

    respond(request, 'after failure');
    await done;

    expect(applied).toEqual(['after failure']);
  });

  describe('latest', () => {
    it('is settled before any request was started', async () => {
      await expect(latest.latest).resolves.toBeUndefined();
    });

    it('follows the most recently started request', async () => {
      const first = new Subject<string>();
      const second = new Subject<string>();
      void latest.apply(first, apply);
      const b = latest.apply(second, apply);

      expect(latest.latest).toBe(b);

      respond(second, 'new');
      await latest.latest;
      expect(applied).toEqual(['new']);
    });
  });

  describe('once cancelled', () => {
    it('drops the request in flight', async () => {
      const request = new Subject<string>();
      const done = latest.apply(request, apply);

      latest.cancel();

      expect(request.observed).toBe(false);
      await expect(done).resolves.toBeUndefined();
    });

    it('starts no further requests', async () => {
      latest.cancel();
      const request = new Subject<string>();

      await expect(latest.apply(request, apply)).resolves.toBeUndefined();
      expect(request.observed).toBe(false);
    });
  });
});
