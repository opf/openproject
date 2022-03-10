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

@Component({
  templateUrl: 'scrollable-tabs.component.html',
  selector: 'op-scrollable-tabs',
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

  private container:Element;

  private pane:Element;

  constructor(
    private cdRef:ChangeDetectorRef,
    public injector:Injector,
  ) { }

  ngAfterViewInit():void {
    this.container = this.scrollContainer.nativeElement;
    this.pane = this.scrollPane.nativeElement;

    this.updateScrollableArea();
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (this.pane) {
      this.updateScrollableArea();
    }
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

  public onScroll(event:any):void {
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
