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

import { defineConfig } from 'vitest/config';

// Loaded by @angular-builders/custom-esbuild:unit-test via the `runnerConfig`
// option in angular.json. The builder layers its browser, setup-file and
// reporter settings on top of this file through an internal plugin, so only
// runner-level options that the builder does not manage belong here.
export default defineConfig({
  test: {
    // The builder defaults this to `false` to mimic Karma/Jasmine, which makes
    // every spec file share one module registry. Specs driving the real
    // Pragmatic adapters and specs mocking those same `@atlaskit` module ids
    // then poison each other: whichever file imports first wins the cache, so
    // the loser sees a real function where it expects a spy.
    isolate: true,

    // jquery-migrate prints this banner to stdout at import time. It is
    // expected, carries no signal, and would otherwise appear once per worker.
    // Filtering here (reporter level) keeps it out of the output without
    // mutating the global `console`, which is the idiomatic Vitest mechanism.
    onConsoleLog(log:string):boolean | void {
      if (log.includes('JQMIGRATE: Migrate is installed')) {
        return false;
      }

      return undefined;
    },
  },
});
