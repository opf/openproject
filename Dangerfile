# Fail if jasmine specs contain fdescribe or fit
fail("jasmine fdescribe left in tests") if `grep --include '*.spec.ts' -rP 'fdescribe|fit' frontend/src/`.length > 1

