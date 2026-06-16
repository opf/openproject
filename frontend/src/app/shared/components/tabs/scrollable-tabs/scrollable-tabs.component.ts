import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, Input, Injector, OnChanges, Output, SimpleChanges, ViewChild, inject } from '@angular/core';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import {
  RawParams,
  StateService,
  UIRouterGlobals,
} from '@uirouter/core';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  templateUrl: 'scrollable-tabs.component.html',
  selector: 'op-scrollable-tabs',
  styleUrls: ['./scrollable-tabs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class ScrollableTabsComponent extends UntilDestroyedMixin implements AfterViewInit, OnChanges {
  protected readonly $state = inject(StateService);
  private cdRef = inject(ChangeDetectorRef);
  injector = inject(Injector);

  @ViewChild('scrollContainer', { static: true }) scrollContainer:ElementRef;

  @ViewChild('scrollPane', { static: true }) scrollPane:ElementRef;

  @ViewChild('scrollRightBtn', { static: true }) scrollRightBtn:ElementRef;

  @ViewChild('scrollLeftBtn', { static: true }) scrollLeftBtn:ElementRef;

  @Input() public currentTabId:string|null = null;

  @Input() public tabs:TabDefinition[] = [];

  @Input() public classes:string[] = [];

  @Input() public hideLeftButton = true;

  @Input() public hideRightButton = true;

  @Output() public tabSelected = new EventEmitter<TabDefinition>();

  readonly uiRouterGlobals = inject(UIRouterGlobals);

  counters:Record<string, Observable<number>> = {};

  private container:Element;

  private pane:Element;

  private resizeObserver:ResizeObserver;

  private debouncedTabActivationTimeout:ReturnType<typeof setTimeout>|null;

  private dragTargetStack = 0;

  ngAfterViewInit():void {
    this.container = this.scrollContainer.nativeElement as HTMLElement;
    this.pane = this.scrollPane.nativeElement as HTMLElement;

    this.resizeObserver = new ResizeObserver(() => this.updateScrollableArea());
    this.resizeObserver.observe(this.container);

    this
      .uiRouterGlobals
      .params$
      ?.pipe(
        this.untilDestroyed(),
      )
      .subscribe((params) => {
        if (params.tabIdentifier) {
          this.currentTabId = params.tabIdentifier as string;
        }
      });
  }

  override ngOnDestroy():void {
    this.resizeObserver?.disconnect();
    super.ngOnDestroy();
  }

  ngOnChanges(_changes:SimpleChanges):void {
    if (this.pane) {
      this.updateScrollableArea();
    }
  }

  counter(tab:TabDefinition):Observable<number>|null {
    if (!tab.counter) {
      return null;
    }

    if (!this.counters[tab.id]) {
      this.counters[tab.id] = tab.counter(this.injector).pipe(share());
    }

    return this.counters[tab.id];
  }

  private updateScrollableArea():void {
    if (!this.pane || !this.container) {
      return;
    }

    this.determineScrollButtonVisibility();
    if (this.currentTabId != null) {
      this.scrollIntoVisibleArea(this.currentTabId);
    }
  }

  public clickTab(tab:TabDefinition, event:Event):void {
    this.currentTabId = tab.id;
    this.tabSelected.emit(tab);

    event.preventDefault();

    // Override history to avoid that browser back leads you to a different tab instead of the page you originated from
    if (tab.path) {
      const historyMethod = document.referrer !== '' ? 'replaceState' : 'pushState';
      history[historyMethod](null, '', tab.path);
    }
  }

  public startDebouncedTabActivation(tab:TabDefinition):void {
    // 'dragenter' events are always fired before 'dragleave' events. Hence, when dragging directly from one tab to
    // another, first the dragenter of the new tab is fired, before we get a dragleave from the old one.
    // Therefor we keep the drag stack, which can raise from 0 to 2. And we only clear the debounced tab activation
    // completely when we fully leave tabs (which means, drag stack is 0).
    this.dragTargetStack += 1;

    if (this.debouncedTabActivationTimeout !== null) {
      this.clearDebouncedTabActivation();
    }

    this.debouncedTabActivationTimeout = setTimeout(() => {
      this.currentTabId = tab.id;
      this.tabSelected.emit(tab);

      const route = this.$state.includes('**.details.*')
        ? this.$state.$current.name
        : tab.route;

      if (route) {
        void this.$state.go(route, tab.routeParams as RawParams);
      }

      this.debouncedTabActivationTimeout = null;
    }, 300);
  }

  public cancelDebouncedTabActivation():void {
    this.dragTargetStack -= 1;

    if (this.dragTargetStack === 0) {
      this.clearDebouncedTabActivation();
    }
  }

  private clearDebouncedTabActivation():void {
    if (this.debouncedTabActivationTimeout !== null) {
      clearTimeout(this.debouncedTabActivationTimeout);
      this.debouncedTabActivationTimeout = null;
    }
  }

  public onScroll():void {
    this.determineScrollButtonVisibility();
  }

  private determineScrollButtonVisibility() {
    this.hideLeftButton = (this.pane.scrollLeft <= 0);
    this.hideRightButton = (this.pane.scrollWidth - this.pane.scrollLeft <= this.container.clientWidth);

    this.cdRef.detectChanges();
  }

  public scrollRight():void {
    this.pane.scrollLeft += this.container.clientWidth;
  }

  public scrollLeft():void {
    this.pane.scrollLeft -= this.container.clientWidth;
  }

  public tabTitle(tab:TabDefinition):string {
    return (typeof tab.disable === 'string') ? tab.disable : tab.name;
  }

  private scrollIntoVisibleArea(tabId:string) {
    const tab = this.pane.querySelector<HTMLElement>(`[data-tab-id=${tabId}]`);
    if (!tab) {
      return;
    }

    const position = getPosition(tab);
    const tabRightBorderAt = position.left + tab.offsetWidth;

    if (this.pane.scrollLeft + this.container.clientWidth < tabRightBorderAt) {
      this.pane.scrollLeft = tabRightBorderAt - this.container.clientWidth + 40; // 40px to not overlap by buttons
    }
  }
}

function getPosition(el:HTMLElement) {
  const offsetParent = el.offsetParent || document.body;
  const elRect = el.getBoundingClientRect();
  const parentRect = offsetParent.getBoundingClientRect();

  return {
    top: elRect.top - parentRect.top - parseFloat(getComputedStyle(offsetParent).borderTopWidth),
    left: elRect.left - parentRect.left - parseFloat(getComputedStyle(offsetParent).borderLeftWidth)
  };
}
