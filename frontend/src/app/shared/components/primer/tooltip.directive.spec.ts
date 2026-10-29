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
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { OpTooltipDirective } from './tooltip.directive';

@Component({
  template: '<button type="button" opTooltip label="Refresh">Refresh</button>',
  imports: [OpTooltipDirective],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class HostComponent {
  readonly label = signal<string|undefined>('Refresh');
  readonly description = signal<string|undefined>(undefined);
  readonly showTooltip = signal(true);
  readonly tooltipId = signal('tip-1');
  readonly hostId = signal('host-1');
  readonly items = signal(['One', 'Two', 'Three']);
}

describe('OpTooltipDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let host:HostComponent;

  async function render(template:string, setup:(component:HostComponent) => void = () => undefined) {
    TestBed.overrideComponent(HostComponent, { set: { template } });
    fixture = TestBed.createComponent(HostComponent);
    host = fixture.componentInstance;
    setup(host);
    await fixture.whenStable();
  }

  async function settle(change:() => void) {
    change();
    await fixture.whenStable();
  }

  const tooltip = () => document.querySelector('tool-tip')!;

  afterEach(() => {
    fixture?.destroy();
  });

  it('upgrades the tool-tip created through ViewContainerRef', async () => {
    await render('<button type="button" opTooltip label="Refresh"><svg></svg></button>');

    const button = screen.getByRole('button');

    expect(button).toHaveAccessibleName('Refresh');
    expect(button.nextElementSibling?.tagName).toBe('TOOL-TIP');
    expect(button.nextElementSibling).toHaveAttribute('role', 'tooltip');

    button.focus();
    await waitFor(() => {
      expect(tooltip().matches(':popover-open')).toBe(true);
    });

    fireEvent.keyDown(document, { key: 'Escape' });
    await waitFor(() => {
      expect(tooltip().matches(':popover-open')).toBe(false);
    });
  });

  it('names an icon-only control from a label tooltip', async () => {
    await render('<button type="button" opTooltip label="Refresh"><svg></svg></button>');

    const button = screen.getByRole('button');

    expect(button).toHaveAccessibleName('Refresh');
    expect(button).not.toHaveAttribute('aria-label');
    expect(tooltip()).toHaveAttribute('aria-hidden', 'true');
  });

  it('describes a control with visible text', async () => {
    await render('<button type="button" opTooltip description="Import BCF file">Import</button>');

    const button = screen.getByRole('button');

    expect(button).toHaveAccessibleName('Import');
    expect(button).toHaveAccessibleDescription('Import BCF file');
    expect(tooltip()).not.toHaveAttribute('aria-hidden');
  });

  it('keeps the label as aria-label when label and description are both given', async () => {
    await render('<button type="button" opTooltip label="Star" description="Add to favorites"><svg></svg></button>');

    const button = screen.getByRole('button');

    expect(button).toHaveAccessibleName('Star');
    expect(button).toHaveAccessibleDescription('Add to favorites');
    expect(button).toHaveAttribute('aria-label', 'Star');
  });

  it('uses aria-label and aria-description when showTooltip is false', async () => {
    await render(
      '<button type="button" opTooltip label="Star" description="Add to favorites" [showTooltip]="false"><svg></svg></button>',
    );

    const button = screen.getByRole('button');

    expect(button).toHaveAttribute('aria-label', 'Star');
    expect(button).toHaveAttribute('aria-description', 'Add to favorites');
    expect(button).toHaveAccessibleName('Star');
    expect(document.querySelector('tool-tip')).toBeNull();
  });

  it('reads showTooltip as a boolean attribute', async () => {
    await render(`
      <button type="button" opTooltip label="Star" showTooltip="false"><svg></svg></button>
      <button type="button" opTooltip label="Refresh" showTooltip><svg></svg></button>
    `);

    expect(screen.getByRole('button', { name: 'Star' })).toHaveAttribute('aria-label', 'Star');
    expect(screen.getByRole('button', { name: 'Refresh' })).not.toHaveAttribute('aria-label');
    expect(document.querySelectorAll('tool-tip')).toHaveLength(1);
  });

  it('renders nothing for empty label and description', async () => {
    await render('<button type="button" opTooltip label="" description="">Plain</button>');

    const button = screen.getByRole('button');

    expect(document.querySelector('tool-tip')).toBeNull();
    expect(button).not.toHaveAttribute('aria-label');
    expect(button).not.toHaveAttribute('aria-description');
    expect(button).not.toHaveAttribute('aria-labelledby');
    expect(button).not.toHaveAttribute('aria-describedby');
  });

  it('reuses an existing host id', async () => {
    await render('<button type="button" id="refresh" opTooltip label="Refresh"><svg></svg></button>');

    expect(screen.getByRole('button')).toHaveAttribute('id', 'refresh');
    expect(tooltip()).toHaveAttribute('for', 'refresh');
  });

  it('generates a host id when missing', async () => {
    await render('<button type="button" opTooltip label="Refresh"><svg></svg></button>');

    const button = screen.getByRole('button');

    expect(button.id).not.toBe('');
    expect(tooltip()).toHaveAttribute('for', button.id);
  });

  it('never replaces a bound host id with a generated one', async () => {
    const replacedValues:(string|null)[] = [];
    const collect = (records:MutationRecord[]) => replacedValues.push(...records.map((record) => record.oldValue));
    const observer = new MutationObserver(collect);
    observer.observe(document.body, { subtree: true, attributeFilter: ['id', 'for'], attributeOldValue: true });

    await render('<button type="button" [attr.id]="hostId()" opTooltip label="Refresh"><svg></svg></button>');
    collect(observer.takeRecords());
    observer.disconnect();

    expect(replacedValues).not.toContainEqual(expect.stringMatching(/^el-/));
    expect(tooltip()).toHaveAttribute('for', 'host-1');
  });

  it('leaves the host without an id when no tooltip renders', async () => {
    await render('<button type="button" opTooltip label="Star" [showTooltip]="false"><svg></svg></button>');

    expect(screen.getByRole('button')).not.toHaveAttribute('id');
  });

  it('keeps existing aria-describedby tokens', async () => {
    await render(`
      <span id="help-1">Opens the importer</span>
      <button type="button" aria-describedby="help-1" opTooltip description="Import BCF file" tooltipId="tip-1">Import</button>
    `);

    const button = screen.getByRole('button');

    expect(button).toHaveAttribute('aria-describedby', 'help-1 tip-1');
    expect(button).toHaveAccessibleDescription('Opens the importer Import BCF file');
  });

  it('keeps existing aria-labelledby tokens', async () => {
    await render(`
      <span id="label-1">Work package</span>
      <button type="button" aria-labelledby="label-1" opTooltip label="Refresh" tooltipId="tip-1"><svg></svg></button>
    `);

    const button = screen.getByRole('button');

    expect(button).toHaveAttribute('aria-labelledby', 'label-1 tip-1');
    expect(button).toHaveAccessibleName('Work package Refresh');
  });

  it('does not describe a label-only control', async () => {
    await render('<button type="button" opTooltip label="Refresh"><svg></svg></button>');

    const button = screen.getByRole('button');

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-labelledby', tooltip().id);
    });
    expect(button).not.toHaveAttribute('aria-describedby');
  });

  it('follows a host id change', async () => {
    await render('<button type="button" [id]="hostId()" opTooltip label="Refresh"><svg></svg></button>');

    const button = screen.getByRole('button');

    await waitFor(() => {
      expect(tooltip()).toHaveAttribute('for', 'host-1');
    });

    await settle(() => host.hostId.set('host-2'));

    await waitFor(() => {
      expect(tooltip()).toHaveAttribute('for', 'host-2');
    });
    expect(button).toHaveAccessibleName('Refresh');

    button.focus();
    await waitFor(() => {
      expect(tooltip().matches(':popover-open')).toBe(true);
    });
  });

  it('switches type both ways', async () => {
    await render(
      '<button type="button" opTooltip [label]="label()" [description]="description()" tooltipId="tip-1"><svg></svg></button>',
    );

    const button = screen.getByRole('button');

    await settle(() => host.description.set('Reload the list'));

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-describedby', 'tip-1');
    });
    expect(button).not.toHaveAttribute('aria-labelledby');
    expect(button).toHaveAttribute('aria-label', 'Refresh');
    expect(tooltip()).not.toHaveAttribute('aria-hidden');
    expect(button).toHaveAccessibleDescription('Reload the list');

    await settle(() => host.description.set(undefined));

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-labelledby', 'tip-1');
    });
    expect(button).not.toHaveAttribute('aria-describedby');
    expect(button).not.toHaveAttribute('aria-label');
    expect(tooltip()).toHaveAttribute('aria-hidden', 'true');
    expect(button).toHaveAccessibleName('Refresh');
  });

  it('changes tooltip id and type together', async () => {
    await render(
      '<button type="button" opTooltip [label]="label()" [description]="description()" [tooltipId]="tooltipId()"><svg></svg></button>',
    );

    const button = screen.getByRole('button');

    await settle(() => {
      host.tooltipId.set('tip-2');
      host.description.set('Reload the list');
    });

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-describedby', 'tip-2');
    });
    expect(button).not.toHaveAttribute('aria-labelledby');
    expect(tooltip()).toHaveAttribute('id', 'tip-2');

    await settle(() => {
      host.tooltipId.set('tip-3');
      host.description.set(undefined);
    });

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-labelledby', 'tip-3');
    });
    expect(button).not.toHaveAttribute('aria-describedby');
  });

  it('toggles showTooltip off and on', async () => {
    await render(`
      <button type="button" aria-label="Original" opTooltip
              [label]="label()" [description]="description()" [showTooltip]="showTooltip()" tooltipId="tip-1">
        Import
      </button>
    `, (component) => {
      component.label.set(undefined);
      component.description.set('Import BCF file');
    });

    const button = screen.getByRole('button');

    expect(button).toHaveAttribute('aria-describedby', 'tip-1');
    expect(button).toHaveAttribute('aria-label', 'Original');

    await settle(() => host.showTooltip.set(false));

    await waitFor(() => {
      expect(document.querySelector('tool-tip')).toBeNull();
    });
    expect(button).not.toHaveAttribute('aria-describedby');
    expect(button).toHaveAttribute('aria-description', 'Import BCF file');
    expect(button).toHaveAttribute('aria-label', 'Original');

    await settle(() => host.label.set('Import file'));

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-label', 'Import file');
    });

    await settle(() => host.showTooltip.set(true));

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-describedby', 'tip-1');
    });
    expect(button).toHaveAttribute('aria-label', 'Import file');
    expect(button).not.toHaveAttribute('aria-description');

    await settle(() => host.label.set(undefined));

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-label', 'Original');
    });
  });

  it('clears label and description', async () => {
    await render(`
      <button type="button" aria-description="Original" opTooltip
              [label]="label()" [description]="description()" [showTooltip]="showTooltip()" tooltipId="tip-1">
        Import
      </button>
    `, (component) => {
      component.label.set(undefined);
      component.description.set('Import BCF file');
      component.showTooltip.set(false);
    });

    const button = screen.getByRole('button');

    expect(button).toHaveAttribute('aria-description', 'Import BCF file');
    expect(button).toHaveAccessibleName('Import');

    await settle(() => host.description.set(''));

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-description', 'Original');
    });
    expect(button).not.toHaveAttribute('aria-label');
    expect(document.querySelector('tool-tip')).toBeNull();
  });

  it('updates the tooltip text', async () => {
    await render('<button type="button" opTooltip [label]="label()"><svg></svg></button>');

    const button = screen.getByRole('button');

    await settle(() => host.label.set('Reload'));

    await waitFor(() => {
      expect(button).toHaveAccessibleName('Reload');
    });
    expect(tooltip()).toHaveTextContent('Reload');
  });

  it('moves and removes tooltips with their hosts in @for', async () => {
    await render(`
      <ul>
        @for (item of items(); track item) {
          <li><button type="button" opTooltip [label]="item"><svg></svg></button></li>
        }
      </ul>
    `);

    const expectTooltipsFollowHosts = (names:string[]) => {
      const buttons = screen.getAllByRole('button');

      expect(buttons.map((button) => button.nextElementSibling?.textContent)).toEqual(names);
      buttons.forEach((button, index) => {
        expect(button).toHaveAccessibleName(names[index]);
      });
    };

    expectTooltipsFollowHosts(['One', 'Two', 'Three']);

    await settle(() => host.items.set(['Three', 'One', 'Two']));
    await waitFor(() => {
      expectTooltipsFollowHosts(['Three', 'One', 'Two']);
    });

    await settle(() => host.items.set(['Three', 'Two']));
    await waitFor(() => {
      expect(document.querySelectorAll('tool-tip')).toHaveLength(2);
    });
    expectTooltipsFollowHosts(['Three', 'Two']);
  });

  describe('tooltipWhenObscured', () => {
    const truncating = 'display:inline-block; overflow:hidden; white-space:nowrap; text-overflow:ellipsis';
    const visuallyHidden = 'position:absolute; width:1px; height:1px; overflow:hidden; clip:rect(0,0,0,0); white-space:nowrap';

    async function focusAndToggle(button:HTMLElement) {
      const toggles:ToggleEvent[] = [];
      tooltip().addEventListener('beforetoggle', (event) => toggles.push(event as ToggleEvent));
      button.focus();
      await waitFor(() => expect(toggles).toHaveLength(1));
      return toggles[0];
    }

    it('opens while the host text is cut off', async () => {
      await render(`<button type="button" opTooltip label="Include sub-projects" tooltipWhenObscured style="${truncating}; max-width:40px">Include sub-projects</button>`);

      const button = screen.getByRole('button');
      button.focus();

      await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
      expect(button).toHaveAccessibleName('Include sub-projects');
    });

    it('stays closed while the host text fits', async () => {
      await render(`<button type="button" opTooltip label="Baseline" tooltipWhenObscured style="${truncating}">Baseline</button>`);

      const button = screen.getByRole('button');
      const toggle = await focusAndToggle(button);

      expect(toggle.defaultPrevented).toBe(true);
      expect(tooltip().matches(':popover-open')).toBe(false);
      expect(button).toHaveAccessibleName('Baseline');
    });

    it('opens while text matched by a selector is visually hidden', async () => {
      await render(`<button type="button" opTooltip label="Baseline" tooltipWhenObscured=".text"><svg></svg><span class="text" style="${visuallyHidden}">Baseline</span></button>`);

      screen.getByRole('button').focus();

      await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
    });

    it('opens while text matched by a selector is not rendered', async () => {
      await render('<button type="button" opTooltip label="Baseline" tooltipWhenObscured=".text"><svg></svg><span class="text" style="display:none">Baseline</span></button>');

      screen.getByRole('button').focus();

      await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
    });

    it('measures a given element, such as an ancestor that cuts off an inline host', async () => {
      await render(`
        <ul>
          <li #crumb style="max-width:40px; overflow:hidden; white-space:nowrap; text-overflow:ellipsis">
            <a href="#crumb" opTooltip label="Parent work package" [tooltipWhenObscured]="crumb">Parent work package</a>
          </li>
        </ul>
      `);

      screen.getByRole('link').focus();

      await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
    });

    it('leaves Escape to other handlers while suppressed', async () => {
      await render(`<button type="button" opTooltip label="Baseline" tooltipWhenObscured style="${truncating}">Baseline</button>`);
      const escapes = vi.fn();
      document.addEventListener('keydown', escapes);

      await focusAndToggle(screen.getByRole('button'));
      fireEvent.keyDown(document, { key: 'Escape' });

      expect(escapes).toHaveBeenCalledOnce();
      document.removeEventListener('keydown', escapes);
    });
  });
});
