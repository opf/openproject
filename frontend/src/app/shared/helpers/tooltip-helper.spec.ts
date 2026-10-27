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

import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { within, waitFor } from '@testing-library/dom';
import { withTooltip } from './tooltip-helper';

type NativeTooltip = InstanceType<typeof window.ToolTipElement>;

describe('withTooltip', () => {
  let owner:HTMLElement;

  beforeEach(() => { owner = document.body.appendChild(document.createElement('div')); });

  afterEach(() => owner.remove());

  function mount(text = 'Open details view', type:'label'|'description' = 'label', content = '') {
    const link = document.createElement('a');
    link.href = '#details';
    link.textContent = content;
    owner.append(withTooltip(link, text, type));
    return { link, tooltip: owner.querySelector<NativeTooltip>('tool-tip')! };
  }

  it('labels an icon-only real link through its sibling tooltip', () => {
    mount();
    const link = within(owner).getByRole('link', { name: 'Open details view' });
    expect(link).toHaveAccessibleDescription('');
    expect(link).toHaveAttribute('title', '');
    expect(link.nextElementSibling).toHaveAttribute('for', link.id);
    expect(link.nextElementSibling).toHaveAttribute('aria-hidden', 'true');
    expect(link.nextElementSibling).toHaveAttribute('data-direction', 's');
  });

  it('describes a value link while preserving its visible name', () => {
    mount('View spent time', 'description', '4 h');
    const link = within(owner).getByRole('link', { name: '4 h' });
    expect(link).toHaveAccessibleDescription('View spent time');
    expect(link).toHaveAttribute('title', '');
  });

  it.each(['label', 'description'] as const)('preserves unrelated ARIA tokens for %s', (type) => {
    const link = document.createElement('a');
    link.id = 'existing-control';
    link.href = '#details';
    const attribute = type === 'label' ? 'aria-labelledby' : 'aria-describedby';
    link.setAttribute(attribute, 'existing-first existing-last');

    const fragment = withTooltip(link, 'Hint', type);
    const tooltip = fragment.querySelector('tool-tip')!;
    expect(link).toHaveAttribute(attribute, `existing-first existing-last ${tooltip.id}`);
    expect(tooltip).toHaveAttribute('for', 'existing-control');

    owner.append(fragment);

    expect(link).toHaveAttribute(attribute, `existing-first existing-last ${tooltip.id}`);
  });

  it('omits an empty hint and suppresses inherited native titles', () => {
    owner.title = 'Inherited hint';
    const { link } = mount('', 'description', 'DEMO-7');
    expect(owner.childNodes).toHaveLength(1);
    expect(link).toHaveAccessibleName('DEMO-7');
    expect(link).toHaveAccessibleDescription('');
    expect(link).toHaveAttribute('title', '');
  });

  it('builds a detached control before its tooltip and allocates distinct occurrence IDs', () => {
    const links = [document.createElement('a'), document.createElement('a')];
    const fragments = links.map((link) => withTooltip(link, 'Hint', 'label'));
    const tooltips = fragments.map((fragment) => fragment.querySelector('tool-tip')!);

    fragments.forEach((fragment, index) => {
      expect(fragment.firstChild).toBe(links[index]);
      expect(fragment.lastChild).toBe(tooltips[index]);
      expect(links[index]).not.toBeInTheDocument();
      expect(tooltips[index]).not.toBeInTheDocument();
    });
    expect(new Set([...links, ...tooltips].map((element) => element.id)).size).toBe(4);

    fragments.forEach((fragment) => owner.append(fragment));

    tooltips.forEach((tooltip, index) => expect(tooltip).toHaveAttribute('for', links[index].id));
  });

  it('shows on real focus, closes on Escape, and shows on hover', async () => {
    const { link, tooltip } = mount();

    link.focus();
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(true));

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }));
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(false));

    link.dispatchEvent(new MouseEvent('mouseenter'));
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(true));

    link.dispatchEvent(new MouseEvent('mouseleave'));
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(false));
  });

  it('disconnects old-control behavior on replacement and connects the replacement', async () => {
    const old = mount();
    old.link.focus();
    await waitFor(() => expect(old.tooltip.matches(':popover-open')).toBe(true));

    const oldHandler = vi.spyOn(old.tooltip, 'handleEvent');
    const oldShow = vi.spyOn(old.tooltip, 'showPopover');
    owner.replaceChildren();
    const replacement = mount();
    old.link.dispatchEvent(new MouseEvent('mouseenter'));
    old.link.dispatchEvent(new FocusEvent('focus'));
    await Promise.resolve();

    expect(oldHandler).not.toHaveBeenCalled();
    expect(oldShow).not.toHaveBeenCalled();
    expect(old.tooltip).not.toBeInTheDocument();

    replacement.link.focus();
    await waitFor(() => expect(replacement.tooltip.matches(':popover-open')).toBe(true));
  });

  it('preserves native showPopover errors while connected', () => {
    const { tooltip } = mount();
    tooltip.removeAttribute('popover');

    expect(() => tooltip.showPopover()).toThrow();
  });

  it('finishes pending focus after synchronous owner removal', async () => {
    const { link, tooltip } = mount();

    const nativeHandleEvent = tooltip.handleEvent.bind(tooltip);
    let pending:Promise<void>|undefined;

    vi.spyOn(tooltip, 'handleEvent').mockImplementation((event:Event) => {
      pending = nativeHandleEvent(event);
      return pending;
    });

    link.focus();
    owner.remove();

    expect(pending).toBeDefined();
    await expect(pending).resolves.toBeUndefined();
  });
});
