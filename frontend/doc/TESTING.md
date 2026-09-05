# Testing the frontend

**How to run the suite** — including the browser matrix and watch mode — is documented once, in
[Running tests locally](https://www.openproject.org/docs/development/testing/running-tests-locally/#frontend-tests).
This page covers what is specific to writing frontend specs.

## What runs, and what bootstraps it

OpenProject is a hybrid application. Server-rendered Rails views with [Hotwire](https://hotwired.dev/)
(Turbo and Stimulus) are the current approach; the Angular frontend is legacy and is being migrated
away from. Both are covered by the same command, and only files ending in `.spec.ts` are matched.

`ng test` builds the specs with esbuild through the Angular CLI and executes them with
[Vitest](https://vitest.dev/). **Angular bootstraps the run even for specs that touch no Angular
code**, so a Stimulus or Turbo spec still needs the Angular build to succeed — a compile error in the
Angular tree fails specs that have nothing to do with it.

Specs run in real browsers driven by [Playwright](https://playwright.dev/), not in a DOM shim. That
means layout, focus and event behaviour are real, and an engine-specific bug surfaces in CI rather
than in review.

## Writing assertions

Assertions come from Vitest, extended with [jest-dom](https://github.com/testing-library/jest-dom)
matchers (`toBeVisible`, `toHaveAccessibleName`, and so on), and queries from
[DOM Testing Library](https://testing-library.com/docs/dom-testing-library/intro/). Prefer querying
the way a user finds things — by role, label or text — over CSS selectors and test-only attributes.

## Stimulus controllers

Two helpers in `src/stimulus/test-helpers.ts` cover the two things worth testing.

**Mount real markup and let Stimulus drive it.** `setupStimulusTest` starts an application, registers
the controllers under test, and returns a context with a Testing Library `screen` scoped to the
mounted container:

```typescript
import { userEvent } from 'vitest/browser';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import CheckableController from 'core-stimulus/controllers/checkable.controller';

let ctx:StimulusTestContext;

afterEach(() => ctx?.dispose());

it('checks every box when the button is pressed', async () => {
  ctx = await setupStimulusTest({ controllers: { checkable: CheckableController } });
  await ctx.mount(`
    <div data-controller="checkable">
      <button data-action="checkable#checkAll">Check all</button>
      <label>First <input type="checkbox" data-checkable-target="checkbox"></label>
    </div>
  `);

  await userEvent.click(ctx.screen.getByRole('button', { name: 'Check all' }));

  expect(ctx.screen.getByRole('checkbox', { name: 'First' })).toBeChecked();
});
```

Dispose in `afterEach` rather than at the end of the test: an assertion failure would otherwise skip
cleanup, and disposal is also where the helper surfaces errors Stimulus swallowed.

This is the default. It exercises the controller through its real contract — identifier, targets,
actions — so a rename that breaks consumers fails the spec.

**Call a method in isolation.** `createControllerInstance` builds an instance without connecting it
to the DOM, for logic that would otherwise need a lot of markup to reach:

```typescript
const controller = createControllerInstance(CheckableController);
Object.defineProperty(controller, 'checkboxTargets', { value: inputs });

controller.toggleAll(new Event('click'));

expect(inputs.every((input) => input.checked)).toBe(true);
```

Target properties are declared `readonly`, so they are supplied with `Object.defineProperty` rather
than assigned. Do not reach for an `any` cast to get around it — that discards exactly the type
checking that makes the isolated test worth writing. Reach for this only when the
behaviour is worth testing apart from its markup — a controller tested solely this way can pass while
being unusable from HTML.

## Angular components

Angular's own [testing guide](https://angular.dev/guide/testing) applies. Note that specs run
zoneless: mutating a plain component field and calling `detectChanges()` will not update the view, so
use signals for state the template reads.

Broader patterns for Angular code are in the
[frontend style guide](https://www.openproject.org/docs/development/style-guide/frontend/).

## Tooling specs

The Node-side tooling under `frontend/tooling/` — the TypeDoc plugin and its harness — has its own
suite, since it cannot run in the browser project:

```shell
npm run test:tooling
```

It uses `vitest.tooling.config.ts`, which covers `tooling/**/*.spec.mjs` in the Node environment.

## Coverage

Pass `--coverage` to collect a report through `@vitest/coverage-v8`. There is no enforced threshold;
it is for finding untested paths, not for gating.

## See also

- [Testing architecture](https://www.openproject.org/docs/development/testing/) — how frontend specs fit the wider
  test strategy, including where feature specs take over.
