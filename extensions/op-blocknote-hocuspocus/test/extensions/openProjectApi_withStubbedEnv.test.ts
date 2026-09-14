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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { onAuthenticatePayload } from "@hocuspocus/server";
import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";
import { OpenProjectApi } from "../../src/extensions/openProjectApi";
import { server } from "../mocks/node";

describe("when an override URL for the OpenProject instance is defined", () => {
  beforeAll(() => {
    vi.hoisted(() => {
      vi.stubEnv("OPENPROJECT_URL", "https://my.op-instance.com/");
    });
  });

  afterAll(() => {
    vi.unstubAllEnvs();
  });

  test("the request is made to the override URL transparently", async () => {
    const requestedUrls: string[] = [];

    server.events.on('request:end', ({ request }) => {
      requestedUrls.push(request.url);
    })

    const data = {
      context: {},
      connectionConfig: {},
      token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
      documentName: "https://test.api/api/v3/documents/1",
    } as unknown as onAuthenticatePayload;

    await new OpenProjectApi().onAuthenticate(data);

    expect(data.context.resourceUrl).toEqual("https://test.api/api/v3/documents/1");
    expect(data.context.token).toEqual("some_token_value");
    expect(data.documentName).toEqual("https://test.api/api/v3/documents/1");

    // request by onAuthenticate made against override URL
    expect(requestedUrls).toEqual(["https://my.op-instance.com/api/v3/documents/1"])
  });
});
