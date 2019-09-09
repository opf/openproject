# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
declared_trivial = github.pr_title.include? "#trivial"

fail("jasmine fdescribe left in tests") if `grep --include '*.spec.ts' -rP 'fdescribe|fit' frontend/src/`.length > 1

