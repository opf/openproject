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

import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { TabPanelDirective } from './tab-panel.directive';
import { TabPanelSource } from './tab-panel-source';

@Component({
  imports: [TabPanelDirective],
  template: `
    <button id="tab-columns" role="tab">Columns</button>
    <button id="tab-sort" role="tab">Sort by</button>
    <div [opTabPanel]="source()">Content</div>
  `,
})
class HostComponent {
  readonly selected = signal<string|null>('tab-columns');

  readonly source = signal<TabPanelSource|null>({
    panelId: signal('panel-x'),
    selectedTabElementId: this.selected,
  });
}

describe('TabPanelDirective', () => {
  function render() {
    const fixture = TestBed.createComponent(HostComponent);
    fixture.detectChanges();
    return fixture;
  }

  it('labels the panel by the selected tab', () => {
    render();

    const panel = screen.getByRole('tabpanel', { name: 'Columns' });
    expect(panel).toHaveAttribute('id', 'panel-x');
    expect(panel).toHaveAttribute('tabindex', '0');
  });

  it('follows the selection', () => {
    const fixture = render();

    fixture.componentInstance.selected.set('tab-sort');
    fixture.detectChanges();

    expect(screen.getByRole('tabpanel', { name: 'Sort by' })).toBeInTheDocument();
  });

  it('renders a plain container without a source', () => {
    const fixture = render();

    fixture.componentInstance.source.set(null);
    fixture.detectChanges();

    expect(screen.queryByRole('tabpanel')).toBeNull();
    expect(screen.getByText('Content')).not.toHaveAttribute('id');
  });
});
