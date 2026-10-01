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

import KeepCollapsedStateController from './keep-collapsed-state.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

// Mirrors the contract both Primer collapsibles share, including Catalyst's
// boolean-attribute semantics: `collapsed` reflects the presence of
// `data-collapsed`, and `toggle()` flips it.
class StubCollapsible extends HTMLElement {
  get collapsed():boolean {
    return this.hasAttribute('data-collapsed');
  }

  toggle():void {
    this.toggleAttribute('data-collapsed', !this.collapsed);
  }
}

class StubCollapsibleHeader extends StubCollapsible {}
class StubCollapsibleSection extends StubCollapsible {}

if (!customElements.get('collapsible-header')) {
  customElements.define('collapsible-header', StubCollapsibleHeader);
}
if (!customElements.get('collapsible-section')) {
  customElements.define('collapsible-section', StubCollapsibleSection);
}

describe('KeepCollapsedStateController', () => {
  let ctx:StimulusTestContext;

  const collapsible = (tag:string, key:string, state:string) => `
<${tag} ${state}>
  <button type="button" data-collapsible-toggle aria-controls="${key}"></button>
</${tag}>`;

  const content = (header:string, section:string) => `
<div id="content">
  ${collapsible('collapsible-header', 'page_links_list', header)}
  ${collapsible('collapsible-section', 'details_content', section)}
</div>`;

  const COLLAPSED = 'data-collapsed="true"';

  const HTML = `
<div data-controller="keep-collapsed-state">
  ${content(COLLAPSED, COLLAPSED)}
</div>`;

  const find = (tag:string) => ctx.container.querySelector<StubCollapsible>(tag)!;
  const collapsed = (tag:string) => find(tag).hasAttribute('data-collapsed');

  // Stands in for a turbo frame or turbo stream render, which always brings
  // the collapsibles back in the state the server rendered.
  const rerender = async (header = COLLAPSED, section = COLLAPSED) => {
    ctx.container.querySelector('#content')!.outerHTML = content(header, section);
    await ctx.nextFrame();
  };

  const toggle = async (tag:string) => {
    find(tag).toggle();
    await ctx.nextFrame();
  };

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { 'keep-collapsed-state': KeepCollapsedStateController } });
    await ctx.mount(HTML);
  });

  afterEach(() => {
    ctx.dispose();
  });

  it('keeps an expanded collapsible expanded across a re-render', async () => {
    await toggle('collapsible-header');

    await rerender();

    expect(collapsed('collapsible-header')).toBe(false);
  });

  it('leaves untouched collapsibles in the state the server rendered', async () => {
    await toggle('collapsible-header');

    await rerender();

    expect(collapsed('collapsible-section')).toBe(true);
  });

  it('keeps a collapsed collapsible collapsed when the server renders it expanded', async () => {
    await rerender('', '');
    await toggle('collapsible-section');

    await rerender('', '');

    expect(collapsed('collapsible-section')).toBe(true);
  });

  it('restores the state again on every subsequent re-render', async () => {
    await toggle('collapsible-section');

    await rerender();
    await rerender();

    expect(collapsed('collapsible-section')).toBe(false);
  });

  // The remembered state lives and dies with the mounted element, which is what returns the boxes to their default
  // once the user leaves the tab.
  it('forgets everything once its element leaves the DOM', async () => {
    await toggle('collapsible-header');

    const root = ctx.container.querySelector('[data-controller="keep-collapsed-state"]')!;
    root.remove();
    await ctx.nextFrame();
    ctx.container.appendChild(root);
    await ctx.nextFrame();

    await rerender();

    expect(collapsed('collapsible-header')).toBe(true);
  });

  it('ignores collapsibles whose toggle controls a different id on re-render', async () => {
    await toggle('collapsible-header');

    ctx.container.querySelector('#content')!.outerHTML = `
<div id="content">
  ${collapsible('collapsible-header', 'regenerated_id_list', COLLAPSED)}
</div>`;
    await ctx.nextFrame();

    expect(collapsed('collapsible-header')).toBe(true);
  });
});
