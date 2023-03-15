import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  Injector,
  OnChanges,
  Output,
  SimpleChanges,
  ViewChild,
} from '@angular/core';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import { trackByProperty } from 'core-app/shared/helpers/angular/tracking-functions';
import { RawParams, StateService } from '@uirouter/core';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';

@Component({
  templateUrl: 'scrollable-tabs.component.html',
  selector: 'op-scrollable-tabs',
  styleUrls: ['./scrollable-tabs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})

export class ScrollableTabsComponent implements AfterViewInit, OnChanges {
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

  trackById = trackByProperty('id');

  counters:Record<string, Observable<number>> = {};

  private container:Element;

  private pane:Element;

  private debouncedTabActivationTimeout:NodeJS.Timeout|null;

  private dragTargetStack = 0;

  constructor(
    protected readonly $state:StateService,
    private cdRef:ChangeDetectorRef,
    public injector:Injector,
  ) { }

  ngAfterViewInit():void {
    this.container = this.scrollContainer.nativeElement as HTMLElement;
    this.pane = this.scrollPane.nativeElement as HTMLElement;

    this.updateScrollableArea();
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

  private updateScrollableArea() {
    this.determineScrollButtonVisibility();
    if (this.currentTabId != null) {
      this.scrollIntoVisibleArea(this.currentTabId);
    }
  }

  public clickTab(tab:TabDefinition, event:Event):void {
    this.currentTabId = tab.id;
    this.tabSelected.emit(tab);

    // If the tab does not provide its own link,
    // avoid propagation
    if (!tab.path) {
      event.preventDefault();
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
    const tab:JQuery<Element> = jQuery(this.pane).find(`[data-tab-id=${tabId}]`);
    const position:JQueryCoordinates = tab.position();

    const tabRightBorderAt:number = position.left + Number(tab.outerWidth());

    if (this.pane.scrollLeft + this.container.clientWidth < tabRightBorderAt) {
      this.pane.scrollLeft = tabRightBorderAt - this.container.clientWidth + 40; // 40px to not overlap by buttons
    }
  }
}
