import { defineConfig } from 'vitest/config';

// Loaded by @angular-builders/custom-esbuild:unit-test via the `runnerConfig`
// option in angular.json. The builder layers its browser, setup-file and
// reporter settings on top of this file through an internal plugin, so only
// runner-level options that the builder does not manage belong here.
export default defineConfig({
  test: {
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
