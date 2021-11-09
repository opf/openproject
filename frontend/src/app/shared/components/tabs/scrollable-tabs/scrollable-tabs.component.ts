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
  HostBinding,
} from '@angular/core';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import { trackByProperty } from 'core-app/shared/helpers/angular/tracking-functions';

@Component({
  templateUrl: 'scrollable-tabs.component.html',
  selector: 'op-scrollable-tabs',
  changeDetection: ChangeDetectionStrategy.OnPush,
})

export class ScrollableTabsComponent implements AfterViewInit, OnChanges {
  @HostBinding('class') get classNames():string {
    return [
      'op-scrollable-tabs',
      ...this.classes,
    ].join(' ');
  }

  @ViewChild('scrollPane', { static: true }) scrollPane:ElementRef;

  @ViewChild('scrollRightBtn', { static: true }) scrollRightBtn:ElementRef;

  @ViewChild('scrollLeftBtn', { static: true }) scrollLeftBtn:ElementRef;

  @Input() public currentTabId:string|null = null;

  @Input() public tabs:TabDefinition[] = [];

  @Input() public classes:string[] = [];

  @Output() public tabSelected = new EventEmitter<TabDefinition>();

  trackById = trackByProperty('id');

  private pane:Element;

  public hideLeftButton = true;

  public hideRightButton = true;

  constructor(
    readonly container:ElementRef,
    private cdRef:ChangeDetectorRef,
    public injector:Injector,
  ) { }

  ngAfterViewInit():void {
    this.pane = this.scrollPane.nativeElement;
    setTimeout(() => this.updateScrollableArea());
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
    this.hideLeftButton = this.pane.scrollLeft <= 0;
    this.hideRightButton = (this.pane.scrollWidth - this.pane.scrollLeft <= (this.container.nativeElement as HTMLElement).clientWidth);

    this.cdRef.detectChanges();
  }

  public scrollRight():void {
    this.pane.scrollLeft += (this.container.nativeElement as HTMLElement).clientWidth;
  }

  public scrollLeft():void {
    this.pane.scrollLeft -= (this.container.nativeElement as HTMLElement).clientWidth;
  }

  public tabTitle(tab:TabDefinition):string {
    return (typeof tab.disable === 'string') ? tab.disable : tab.name;
  }

  private scrollIntoVisibleArea(tabId:string) {
    const tab = this.pane.querySelectorAll(`[data-tab-id=${tabId}]`)[0] as HTMLElement;

    const tabRightBorderAt:number = tab.offsetLeft + tab.offsetWidth;

    if (this.pane.scrollLeft + (this.container.nativeElement as HTMLElement).clientWidth < tabRightBorderAt) {
      this.pane.scrollLeft = tabRightBorderAt - (this.container.nativeElement.clientWidth).clientWidth + 40; // 40px to not overlap by buttons
    }
  }
}
