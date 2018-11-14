import {
  Component,
  OnDestroy,
  Input,
  AfterViewInit} from "@angular/core";

@Component({
  selector: 'widget-resizer',
  templateUrl: './widget-resizer.component.html'
})
export class WidgetResizerComponent implements OnDestroy, AfterViewInit {
  private oldX:number;
  private oldY:number;
  //private newX:number;
  //private newY:number;
  //private newWidth:number;
  //private newHeight:number;
  private mouseMoveHandler:EventListener;
  private mouseUpHandler:EventListener;
  private resizing = false;

  // TODO: refactor
  private widget:JQuery;

  @Input() areaId:string;

  ngOnDestroy() {
    this.removeEventListener();
  }

  ngAfterViewInit() {
    this.widget = jQuery(`#${this.areaId}`).find('widget-box');
  }

  public startResize(event:MouseEvent) {
    console.log('resize down');

    event.preventDefault();
    event.stopPropagation();

    // Only on left mouse click the resizing is started
    if (event.buttons === 1 || event.which === 1) {
      // Getting starting position
      this.oldX = event.clientX;
      this.oldY = event.clientY;

      //this.newWidth = this.widget.width();
      //this.newHeight = this.widget.height();

      this.resizing = true;

      this.setResizeCursor();
      //this.mouseMoveHandler = this.onMouseMove.bind(this, event.currentTarget);
      //this.mouseUpHandler = this.onMouseUp.bind(this, event.currentTarget);
      this.bindEventListener(event);
    }
  }

  private onMouseUp(element:HTMLElement, event:MouseEvent) {
    console.log('resize up');

    this.setAutoCursor();

    this.removeEventListener();
  }

  private onMouseMove(element:HTMLElement, event:MouseEvent) {
    console.log(event.clientX);
    event.preventDefault();
    event.stopPropagation();

    console.log(event.clientX);
    let deltaX = event.clientX - this.oldX;
    let deltaY = event.clientY - this.oldY;

    console.log(deltaX);
    console.log(deltaY);
    //this.oldPosition = e.clientX;
    //this.elementWidth = this.elementWidth + delta;

    //this.toggleService.saveWidth(this.elementWidth);
  }

  // Necessary to encapsulate this to be able to remove the event listener later
  private bindEventListener(event:MouseEvent) {
    this.mouseMoveHandler = this.onMouseMove.bind(this, event.currentTarget);
    this.mouseUpHandler = this.onMouseUp.bind(this, event.currentTarget);

    window.addEventListener('mousemove', this.mouseMoveHandler);
    window.addEventListener('mouseup', this.mouseUpHandler);
  }

  private removeEventListener() {
    window.removeEventListener('mousemove', this.mouseMoveHandler);
    window.removeEventListener('mouseup', this.mouseUpHandler);
  }

  private setResizeCursor() {
    this.setCursor('nwse-resize !important');
  }

  private setAutoCursor() {
    this.setCursor('auto');
  }

  // Change cursor icon
  // This is handled via JS to ensure
  // that the cursor stays the same even when the mouse leaves the actual resizer.
  private setCursor(style:string) {
    document.getElementsByTagName("body")[0].setAttribute('style',
      `cursor: ${style}`);
  }
}
