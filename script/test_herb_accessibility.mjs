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

import assert from "node:assert/strict";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { Config } from "@herb-tools/config";
import { Linter } from "@herb-tools/linter";
import { Herb } from "@herb-tools/node-wasm";

const root = fileURLToPath(new URL("../", import.meta.url));
const config = await Config.load(root, { createIfMissing: false, silent: true });
await Herb.load();

const cases = [
  ["html-aria-label-is-well-formatted", '<button aria-label="save">Save</button>', '<button aria-label="Save">Save</button>'],
  ["html-avoid-both-disabled-and-aria-disabled", '<button disabled aria-disabled="true">Save</button>', '<button aria-disabled="true">Save</button>'],
  ["a11y-avoid-generic-link-text", '<a href="/guide">Read more</a>', '<a href="/guide">Read the guide</a>'],
  ["a11y-disabled-attribute", "<div disabled>Content</div>", "<button disabled>Save</button>"],
  ["html-iframe-has-title", '<iframe src="/video"></iframe>', '<iframe src="/video" title="Introduction"></iframe>'],
  ["html-img-require-alt", '<img src="/logo.png">', '<img src="/logo.png" alt="">'],
  ["html-navigation-has-label", "<nav></nav>", '<nav aria-label="Main"></nav>'],
  ["html-anchor-require-href", "<a>Guide</a>", '<a href="/guide">Guide</a>'],
  ["a11y-nested-interactive-elements", '<button><a href="/guide">Guide</a></button>', '<summary><a href="/guide">Guide</a></summary>'],
  ["html-no-aria-hidden-on-focusable", '<button aria-hidden="true">Save</button>', '<button aria-hidden="false">Save</button>'],
  ["a11y-no-aria-label-misuse", '<div aria-label="Content"></div>', '<div role="region" aria-label="Content"></div>'],
  ["html-no-positive-tab-index", '<button tabindex="1">Save</button>', '<button tabindex="0">Save</button>'],
  ["a11y-no-redundant-image-alt", '<img src="/logo.png" alt="Logo image">', '<img src="/logo.png" alt="Logo">'],
  ["html-no-title-attribute", '<button title="Save">Save</button>', '<link rel="stylesheet" href="/style.css" title="Theme">'],
  ["a11y-svg-has-accessible-text", "<svg></svg>", '<svg aria-hidden="true"></svg>'],
  ["a11y-no-visually-hidden-interactive-elements", '<button class="sr-only">Save</button>', '<button class="sr-only focus:not-sr-only">Save</button>'],
];

function offenses(source, filename = "app/views/accessibility.html.erb") {
  return Linter.from(Herb, config).lint(source, { fileName: filename }).offenses;
}

for (const [rule, invalid, valid] of cases) {
  test(`${rule} is enabled and blocking`, () => {
    assert.equal(config.linter.rules[rule].enabled, true);
    assert.equal(config.linter.rules[rule].severity, "error");
    const failures = offenses(invalid).filter(offense => offense.code === rule);
    assert.equal(failures.length, 1);
    assert.equal(failures[0].severity, "error");
  });

  test(`${rule} accepts accessible markup`, () => {
    assert.equal(offenses(valid).filter(offense => offense.code === rule).length, 0);
  });

  test(`${rule} preserves the deprecated-preview exclusion`, () => {
    const filename = "lookbook/previews/open_project/deprecated/accessibility_preview/default.html.erb";
    assert.equal(offenses(invalid, filename).filter(offense => offense.code === rule).length, 0);
  });
}

test("existing placeholder-link exceptions remain scoped to their files", () => {
  const source = '<a href="#">Expand</a>';
  assert.equal(offenses(source, "app/components/members/role_form_component.html.erb")
    .filter(offense => offense.code === "html-anchor-require-href").length, 0);
  assert.equal(offenses(source).filter(offense => offense.code === "html-anchor-require-href").length, 1);
});

test("accessibility offenses support line-scoped suppression", () => {
  const source = '<button class="sr-only">Save</button> <%# herb:disable a11y-no-visually-hidden-interactive-elements %>';
  assert.equal(offenses(source).filter(offense => offense.code === "a11y-no-visually-hidden-interactive-elements").length, 0);
});

test("the skip-link counter suppresses exactly one offense", () => {
  const source = '<%# herb:disable a11y-no-visually-hidden-interactive-elements 1 %>\n<a href="#content" class="sr-only skip-navigation-link">Content</a>';
  assert.equal(offenses(source).filter(offense => offense.code === "a11y-no-visually-hidden-interactive-elements").length, 0);
  assert.ok(offenses(`${source}\n<button class="sr-only">Save</button>`)
    .some(offense => offense.code === "herb-disable-comment-out-of-date"));
});
