import {AfterViewInit, Component, ElementRef, ViewChild} from "@angular/core";

@Component({
  templateUrl: 'scrollable-tabs.component.html'
})

export class ScrollableTabsComponent implements AfterViewInit {
  @ViewChild('scrollContainer') scrollContainer:ElementRef;
  @ViewChild('scrollPane') scrollPane:ElementRef;
  @ViewChild('scrollRightBtn') scrollRightBtn:ElementRef;
  @ViewChild('scrollLeftBtn') scrollLeftBtn:ElementRef;

  public currentTabId:string = '';
  public tabs:{id:string, name:string}[] = [];
  public classes:string[] = ['scrollable-tabs'];
  public hideLeftButton:boolean = true;
  public hideRightButton:boolean = true;

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
