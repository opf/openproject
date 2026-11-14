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

import {
  afterNextRender,
  afterRenderEffect,
  Component,
  computed,
  DestroyRef,
  ElementRef,
  inject,
  Injector,
  input,
  model,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import { TabPanelSource } from 'core-app/shared/components/tabs/tab-panel-source';

@Component({
  templateUrl: 'scrollable-tabs.component.html',
  selector: 'op-scrollable-tabs',
  styleUrls: ['./scrollable-tabs.component.sass'],
  standalone: false,
})
export class ScrollableTabsComponent implements TabPanelSource {
  private readonly I18n = inject(I18nService);

  readonly injector = inject(Injector);

  readonly tabs = input<TabDefinition[]>([]);

  readonly currentTabId = model<string|null>(null);

  readonly label = input<string>();

  readonly panelId = input(generateId('op-tab-panel'));

  readonly tabSelected = output<TabDefinition>();

  readonly selectedTabElementId = computed(() => {
    const id = this.currentTabId();
    return id === null ? null : this.tabElementId(id);
  });

  protected readonly focusableTabId = computed(() => {
    const tabs = this.tabs();
    const current = this.currentTabId();
    if (tabs.some((tab) => tab.id === current)) {
      return current;
    }
    return tabs.find((tab) => tab.disable === undefined)?.id ?? null;
  });

  protected readonly hideLeftButton = signal(true);

  protected readonly hideRightButton = signal(true);

  protected readonly text = {
    scrollLeft: this.I18n.t('js.label_scroll_left'),
    scrollRight: this.I18n.t('js.label_scroll_right'),
  };

  private readonly scrollContainer = viewChild.required<ElementRef<HTMLElement>>('scrollContainer');

  private readonly scrollPane = viewChild.required<ElementRef<HTMLElement>>('scrollPane');

  private readonly idPrefix = generateId('op-scrollable-tabs');

  private readonly counters:Record<string, Observable<number>> = {};

  private debouncedTabActivationTimeout:ReturnType<typeof setTimeout>|null = null;

  private dragTargetStack = 0;

  constructor() {
    const destroyRef = inject(DestroyRef);

    afterNextRender(() => {
      const observer = new ResizeObserver(() => this.updateScrollableArea());
      observer.observe(this.scrollContainer().nativeElement);
      destroyRef.onDestroy(() => observer.disconnect());
    });

    afterRenderEffect(() => {
      this.tabs();
      this.currentTabId();
      this.updateScrollableArea();
    });

    destroyRef.onDestroy(() => this.clearDebouncedTabActivation());
  }

  tabElementId(tabId:string):string {
    return `${this.idPrefix}-tab-${tabId}`;
  }

  counter(tab:TabDefinition):Observable<number>|null {
    if (!tab.counter) {
      return null;
    }

    this.counters[tab.id] ??= tab.counter(this.injector).pipe(share());

    return this.counters[tab.id];
  }

  activate(tab:TabDefinition):void {
    if (tab.disable !== undefined) {
      return;
    }

    this.currentTabId.set(tab.id);
    this.tabSelected.emit(tab);
    this.syncHistory(tab);
  }

  onKeydown(event:KeyboardEvent, index:number):void {
    if (event.altKey || event.ctrlKey || event.metaKey) {
      return;
    }

    const tabs = this.tabs();
    const target = this.targetIndex(event.code, index, tabs.length);
    if (target === null) {
      return;
    }

    event.preventDefault();
    const tab = tabs[target];
    this.activate(tab);
    document.getElementById(this.tabElementId(tab.id))?.focus();
  }

  disabledReason(tab:TabDefinition):string|undefined {
    return typeof tab.disable === 'string' ? tab.disable : undefined;
  }

  startDebouncedTabActivation(tab:TabDefinition):void {
    // 'dragenter' events are always fired before 'dragleave' events. Hence, when dragging directly from one tab to
    // another, first the dragenter of the new tab is fired, before we get a dragleave from the old one.
    // Therefore we keep the drag stack, which can raise from 0 to 2. And we only clear the debounced tab activation
    // completely when we fully leave tabs (which means, drag stack is 0).
    this.dragTargetStack += 1;
    this.clearDebouncedTabActivation();

    this.debouncedTabActivationTimeout = setTimeout(() => {
      this.currentTabId.set(tab.id);
      this.tabSelected.emit(tab);
      this.debouncedTabActivationTimeout = null;
    }, 300);
  }

  cancelDebouncedTabActivation():void {
    this.dragTargetStack -= 1;

    if (this.dragTargetStack === 0) {
      this.clearDebouncedTabActivation();
    }
  }

  onScroll():void {
    this.determineScrollButtonVisibility();
  }

  scrollRight():void {
    const pane = this.scrollPane().nativeElement;
    pane.scrollLeft += pane.clientWidth;
  }

  scrollLeft():void {
    const pane = this.scrollPane().nativeElement;
    pane.scrollLeft -= pane.clientWidth;
  }

  private targetIndex(code:string, index:number, count:number):number|null {
    switch (code) {
      case 'ArrowRight':
        return (index + 1) % count;
      case 'ArrowLeft':
        return (index - 1 + count) % count;
      case 'Home':
        return 0;
      case 'End':
        return count - 1;
      default:
        return null;
    }
  }

  // Override history to avoid that browser back leads you to a different tab instead of the page you originated from
  private syncHistory(tab:TabDefinition):void {
    if (tab.path) {
      const historyMethod = document.referrer !== '' ? 'replaceState' : 'pushState';
      history[historyMethod](null, '', tab.path);
    }
  }

  private clearDebouncedTabActivation():void {
    if (this.debouncedTabActivationTimeout !== null) {
      clearTimeout(this.debouncedTabActivationTimeout);
      this.debouncedTabActivationTimeout = null;
    }
  }

  private updateScrollableArea():void {
    this.determineScrollButtonVisibility();

    const currentTabId = this.currentTabId();
    if (currentTabId !== null) {
      this.scrollIntoVisibleArea(currentTabId);
    }
  }

  private determineScrollButtonVisibility():void {
    const pane = this.scrollPane().nativeElement;
    this.hideLeftButton.set(pane.scrollLeft <= 0);
    this.hideRightButton.set(pane.scrollWidth - pane.scrollLeft <= pane.clientWidth);
  }

  private scrollIntoVisibleArea(tabId:string):void {
    const tab = document.getElementById(this.tabElementId(tabId));
    if (!tab) {
      return;
    }

    const pane = this.scrollPane().nativeElement;
    const tabRect = tab.getBoundingClientRect();
    const paneRect = pane.getBoundingClientRect();
    if (tabRect.left < paneRect.left) {
      pane.scrollLeft -= paneRect.left - tabRect.left;
    } else if (tabRect.right > paneRect.right) {
      pane.scrollLeft += tabRect.right - paneRect.right;
    }
  }

}
