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

import '@github/tab-container-element';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, within } from '@testing-library/dom';
import { of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import { ScrollableTabsComponent } from './scrollable-tabs.component';

const TABS:TabDefinition[] = [
  { id: 'columns', name: 'Columns' },
  { id: 'gantt', name: 'Gantt chart', disable: 'Not available for embedded tables' },
  { id: 'display', name: 'Display settings', disable: true },
  { id: 'sort', name: 'Sort by', counter: () => of(3) },
];

describe('ScrollableTabsComponent', () => {
  let fixture:ComponentFixture<ScrollableTabsComponent>;

  async function render(currentTabId:string|null = 'columns') {
    const instance = TestBed.createComponent(ScrollableTabsComponent);
    instance.componentRef.setInput('tabs', TABS);
    instance.componentRef.setInput('label', 'Tabs');
    instance.componentRef.setInput('panelId', 'panel-x');
    instance.componentRef.setInput('currentTabId', currentTabId);
    instance.detectChanges();
    await instance.whenStable();
    return instance;
  }

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        imports: [OpenprojectTabsModule],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key, locale: 'en' } },
        ],
      })
      .compileComponents();

    fixture = await render();
  });

  it('renders Primer UnderlinePanels tabs', () => {
    const tablist = screen.getByRole('tablist', { name: 'Tabs' });
    expect(tablist).toHaveClass('UnderlineNav-body', 'list-style-none');
    expect(tablist.closest('tab-container')).not.toBeNull();

    const columns = screen.getByRole('tab', { name: 'Columns' });
    expect(columns.tagName).toBe('BUTTON');
    expect(columns).toHaveClass('UnderlineNav-item');
    expect(columns).toHaveAttribute('aria-controls', 'panel-x');
    expect(columns).toHaveAttribute('aria-selected', 'true');
    expect(columns).toHaveAttribute('tabindex', '0');
    expect(screen.getByRole('tab', { name: /Sort by/ })).toHaveAttribute('tabindex', '-1');
  });

  it('gives tabs unique ids across instances', async () => {
    const other = await render();
    const ids = [fixture, other].map((f) => (f.nativeElement as HTMLElement).querySelector('[role="tab"]')!.id);

    expect(ids[0]).not.toBe('');
    expect(ids[0]).not.toBe(ids[1]);
  });

  it('exposes the selected tab id for its panel', () => {
    const columns = screen.getByRole('tab', { name: 'Columns' });

    expect(fixture.componentInstance.panelId()).toBe('panel-x');
    expect(fixture.componentInstance.selectedTabElementId()).toBe(columns.id);
  });

  it('shows counts with the Primer counter', () => {
    expect(within(screen.getByRole('tab', { name: /Sort by/ })).getByText('3')).toHaveClass('Counter');
  });

  it('emits tabSelected once on click and updates the selection', () => {
    const selected = vi.fn();
    fixture.componentInstance.tabSelected.subscribe(selected);

    fireEvent.click(screen.getByRole('tab', { name: /Sort by/ }));
    fixture.detectChanges();

    expect(selected).toHaveBeenCalledTimes(1);
    expect(selected).toHaveBeenCalledWith(expect.objectContaining({ id: 'sort' }));
    expect(fixture.componentInstance.currentTabId()).toBe('sort');
    expect(screen.getByRole('tab', { name: /Sort by/ })).toHaveAttribute('aria-selected', 'true');
    expect(screen.getByRole('tab', { name: 'Columns' })).toHaveAttribute('aria-selected', 'false');
  });

  it('keeps the selection when arrowing onto a disabled tab', () => {
    const selected = vi.fn();
    fixture.componentInstance.tabSelected.subscribe(selected);
    const columns = screen.getByRole('tab', { name: 'Columns' });

    columns.focus();
    fireEvent.keyDown(columns, { code: 'ArrowRight' });
    fixture.detectChanges();

    expect(selected).not.toHaveBeenCalled();
    expect(columns).toHaveAttribute('aria-selected', 'true');
    expect(screen.getByRole('tab', { name: 'Gantt chart' })).toHaveFocus();
  });

  it('selects tabs with arrow keys, wrapping around', () => {
    const selected = vi.fn();
    fixture.componentInstance.tabSelected.subscribe(selected);
    const columns = screen.getByRole('tab', { name: 'Columns' });

    columns.focus();
    fireEvent.keyDown(columns, { code: 'ArrowLeft' });
    fixture.detectChanges();

    const sort = screen.getByRole('tab', { name: /Sort by/ });
    expect(selected).toHaveBeenCalledWith(expect.objectContaining({ id: 'sort' }));
    expect(sort).toHaveAttribute('aria-selected', 'true');
    expect(sort).toHaveAttribute('tabindex', '0');
    expect(sort).toHaveFocus();
  });

  it('selects the first and last tab with Home and End', () => {
    const columns = screen.getByRole('tab', { name: 'Columns' });

    columns.focus();
    fireEvent.keyDown(columns, { code: 'End' });
    fixture.detectChanges();
    expect(fixture.componentInstance.currentTabId()).toBe('sort');

    fireEvent.keyDown(screen.getByRole('tab', { name: /Sort by/ }), { code: 'Home' });
    fixture.detectChanges();
    expect(fixture.componentInstance.currentTabId()).toBe('columns');
  });

  it('keeps the selected tab fully visible when the tabs start to overflow', async () => {
    const nextFrames = () => new Promise((resolve) => { requestAnimationFrame(() => requestAnimationFrame(resolve)); });
    const narrow = TestBed.createComponent(ScrollableTabsComponent);
    document.body.appendChild(narrow.nativeElement as HTMLElement);
    narrow.componentRef.setInput('tabs', TABS);
    narrow.componentRef.setInput('currentTabId', 'sort');
    narrow.detectChanges();
    await narrow.whenStable();
    await nextFrames();

    (narrow.nativeElement as HTMLElement).style.width = '200px';
    await nextFrames();
    narrow.detectChanges();
    await narrow.whenStable();
    await nextFrames();

    const host = narrow.nativeElement as HTMLElement;
    const pane = host.querySelector('.UnderlineNav')!.getBoundingClientRect();
    const sort = host.querySelector('[role="tab"][aria-selected="true"]')!.getBoundingClientRect();

    expect(sort.left).toBeGreaterThanOrEqual(pane.left - 1);
    expect(sort.right).toBeLessThanOrEqual(pane.right + 1);
  });

  it('lets the user scroll away from the selected tab', async () => {
    const nextFrames = () => new Promise((resolve) => { requestAnimationFrame(() => requestAnimationFrame(resolve)); });
    const narrow = TestBed.createComponent(ScrollableTabsComponent);
    (narrow.nativeElement as HTMLElement).style.width = '200px';
    document.body.appendChild(narrow.nativeElement as HTMLElement);
    narrow.componentRef.setInput('tabs', TABS);
    narrow.componentRef.setInput('label', 'Narrow tabs');
    narrow.componentRef.setInput('currentTabId', 'columns');
    narrow.detectChanges();
    await narrow.whenStable();
    await nextFrames();

    const host = narrow.nativeElement as HTMLElement;
    fireEvent.click(within(host).getByRole('button', { name: 'js.label_scroll_right' }));
    await nextFrames();
    narrow.detectChanges();
    await narrow.whenStable();
    await nextFrames();

    expect(host.querySelector('.UnderlineNav')!.scrollLeft).toBeGreaterThan(0);
  });

  it('does not scroll its scroll container vertically to reveal the tabs', async () => {
    const scroller = document.createElement('div');
    scroller.style.cssText = 'height: 100px; overflow: auto;';
    const spacer = document.createElement('div');
    spacer.style.height = '1000px';
    scroller.appendChild(spacer);
    document.body.appendChild(scroller);

    const below = TestBed.createComponent(ScrollableTabsComponent);
    scroller.appendChild(below.nativeElement as HTMLElement);
    below.componentRef.setInput('tabs', TABS);
    below.componentRef.setInput('currentTabId', 'sort');
    below.detectChanges();
    await below.whenStable();
    await new Promise((resolve) => { requestAnimationFrame(() => requestAnimationFrame(resolve)); });

    expect(scroller.scrollTop).toBe(0);
    scroller.remove();
  });

  it('keeps the first enabled tab reachable when no tab is selected', async () => {
    const unmatched = await render('unknown');

    const tabs = within(unmatched.nativeElement as HTMLElement).getAllByRole('tab');
    expect(tabs.map((tab) => tab.getAttribute('tabindex'))).toEqual(['0', '-1', '-1', '-1']);
  });

  it('leaves arrow keys with modifiers to the browser', () => {
    const selected = vi.fn();
    fixture.componentInstance.tabSelected.subscribe(selected);
    const columns = screen.getByRole('tab', { name: 'Columns' });

    columns.focus();
    const notCancelled = fireEvent.keyDown(columns, { code: 'ArrowLeft', altKey: true });

    expect(notCancelled).toBe(true);
    expect(selected).not.toHaveBeenCalled();
  });

  it('describes a disabled tab by its reason through a tooltip', () => {
    expect(screen.getByRole('tab', { name: 'Gantt chart' }))
      .toHaveAccessibleDescription('Not available for embedded tables');
    expect(screen.getByRole('tablist').querySelectorAll('tool-tip')).toHaveLength(1);
  });

  it('leaves tabs without a reason undescribed', () => {
    expect(screen.getByRole('tab', { name: 'Columns' })).not.toHaveAccessibleDescription();
    expect(screen.getByRole('tab', { name: 'Display settings' })).not.toHaveAccessibleDescription();
  });

  it('marks disabled tabs as disabled while keeping them reachable for their tooltip', () => {
    const gantt = screen.getByRole('tab', { name: 'Gantt chart' });

    expect(gantt).toHaveAttribute('aria-disabled', 'true');
    expect(screen.getByRole('tab', { name: 'Columns' })).not.toHaveAttribute('aria-disabled');
    expect(getComputedStyle(gantt).pointerEvents).not.toBe('none');

    gantt.focus();
    expect(gantt).toHaveFocus();
  });

  it('ignores activation of a disabled tab', () => {
    const selected = vi.fn();
    fixture.componentInstance.tabSelected.subscribe(selected);

    fireEvent.click(screen.getByRole('tab', { name: 'Gantt chart' }));

    expect(selected).not.toHaveBeenCalled();
    expect(fixture.componentInstance.currentTabId()).not.toBe('gantt');
  });
});
