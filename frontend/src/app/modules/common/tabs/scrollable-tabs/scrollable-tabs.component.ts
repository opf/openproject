import { AfterViewInit, Component, ElementRef, ViewChild } from "@angular/core";

export interface Tab {
  id:string;
  name:string;
  path?:string;
}

@Component({
  templateUrl: 'scrollable-tabs.component.html'
})

export class ScrollableTabsComponent implements AfterViewInit {
  @ViewChild('scrollContainer', { static: true }) scrollContainer:ElementRef;
  @ViewChild('scrollPane', { static: true }) scrollPane:ElementRef;
  @ViewChild('scrollRightBtn', { static: true }) scrollRightBtn:ElementRef;
  @ViewChild('scrollLeftBtn', { static: true }) scrollLeftBtn:ElementRef;

  public currentTabId = '';
  public tabs:Tab[] = [];
  public classes:string[] = ['scrollable-tabs'];
  public hideLeftButton = true;
  public hideRightButton = true;

  private container:Element;
  private pane:Element;

  ngAfterViewInit() {
    this.container = this.scrollContainer.nativeElement;
    this.pane = this.scrollPane.nativeElement;

    this.determineScrollButtonVisibility();
    this.scrollIntoVisibleArea(this.currentTabId);
  }

  public clickTab(tab:string) {
    this.currentTabId = tab;
  }

  public onScroll(event:any) {
    this.determineScrollButtonVisibility();
  }

  private determineScrollButtonVisibility() {
    this.hideLeftButton = (this.pane.scrollLeft <= 0);
    this.hideRightButton = (this.pane.scrollWidth - this.pane.scrollLeft <= this.container.clientWidth);
  }

  public scrollRight() {
    this.pane.scrollLeft += this.container.clientWidth;
  }

  public scrollLeft() {
    this.pane.scrollLeft -= this.container.clientWidth;
  }

  private scrollIntoVisibleArea(tabId:string) {
    const tab:JQuery<Element> = jQuery(this.pane).find(`[tab-id=${tabId}]`);
    const position:JQueryCoordinates = tab.position();

    const tabRightBorderAt:number = position.left + Number(tab.outerWidth());

    if (this.pane.scrollLeft + this.container.clientWidth < tabRightBorderAt) {
      this.pane.scrollLeft = tabRightBorderAt - this.container.clientWidth + 40; // 40px to not overlap by buttons
    }
  }
}
