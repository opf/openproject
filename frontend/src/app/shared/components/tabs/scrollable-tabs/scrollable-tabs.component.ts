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
  @HostBinding('class') get classNames() {
    return [
      'op-scrollable-tabs',
      (this.isOnLeft ? 'op-scrollable-tabs_is-on-left' : ''),
      (this.isOnRight ? 'op-scrollable-tabs_is-on-right' : ''),
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

  private isOnLeft = true;

  private isOnRight = false;

  constructor(
    readonly container:ElementRef,
    private cdRef:ChangeDetectorRef,
    public injector:Injector,
  ) { }

  ngAfterViewInit():void {
    this.pane = this.scrollPane.nativeElement;
    setTimeout(() => this.determineScrollButtonVisibility());
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (this.pane) {
      this.determineScrollButtonVisibility();
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
    this.isOnLeft = this.pane.scrollLeft <= 0;
    this.isOnRight = (this.pane.scrollWidth - this.pane.scrollLeft <= this.container.nativeElement.clientWidth);

    this.cdRef.detectChanges();
  }

  public tabTitle(tab:TabDefinition):string {
    return (typeof tab.disable === 'string') ? tab.disable : tab.name;
  }
}
