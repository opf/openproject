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

import { HttpErrorResponse } from '@angular/common/http';
import { toError } from './error-reporter-base';

describe('toError', () => {
  it('returns an Error unchanged', () => {
    const error = new Error('broken');

    expect(toError(error)).toBe(error);
  });

  it('wraps an HTTP error response, keeping its message and the response as cause', () => {
    const response = new HttpErrorResponse({ status: 500, url: '/api/v3/statuses/1' });

    const error = toError(response);

    expect(error).toBeInstanceOf(Error);
    expect(error.message).toBe(response.message);
    expect(error.cause).toBe(response);
  });

  it('wraps a string as the message', () => {
    expect(toError('broken').message).toBe('broken');
  });

  it('wraps any other value as the cause', () => {
    const value = { status: 'odd' };

    expect(toError(value).cause).toBe(value);
  });
});
