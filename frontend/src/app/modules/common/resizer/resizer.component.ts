import {Component, EventEmitter, HostListener, Input, OnDestroy, Output} from "@angular/core";
import {DomHelpers} from "core-app/helpers/dom/set-window-cursor.helper";


export interface ResizeDelta {
  origin:MouseEvent;

  // Absolute difference from start
  absolute:{
    x:number;
    y:number;
  };

  // Relative difference from last position
  relative:{
    x:number;
    y:number;
  };
}

@Component({
  selector: 'resizer',
  templateUrl: './resizer.component.html'
})
export class ResizerComponent implements OnDestroy {
  private startX:number;
  private startY:number;
  private oldX:number;
  private oldY:number;
  private newX:number;
  private newY:number;
  private mouseMoveHandler:EventListener;
  private mouseUpHandler:EventListener;
  private resizing = false;

  @Output() end:EventEmitter<ResizeDelta> = new EventEmitter();
  @Output() start:EventEmitter<ResizeDelta> = new EventEmitter();
  @Output() move:EventEmitter<ResizeDelta> = new EventEmitter();

  @Input() customHandler = false;
  @Input() cursorClass = 'nwse-resize';
  @Input() resizerClass = 'resizer';

  ngOnDestroy() {
    this.removeEventListener();
  }

  @HostListener('mousedown', ['$event'])
  public startResize(event:MouseEvent) {
    event.preventDefault();
    event.stopPropagation();

    // Only on left mouse click the resizing is started
    if (event.buttons === 1 || event.which === 1) {
      // Getting starting position
      this.oldX = this.startX = event.clientX || event.pageX;
      this.oldY = this.startY = event.clientY || event.pageY;

      this.newX = event.clientX || event.pageX;
      this.newY = event.clientY || event.pageY;

      this.resizing = true;

      this.setResizeCursor();
      this.bindEventListener(event);

      this.start.emit(this.buildDelta(event));
    }
  }

  private onMouseUp(element:HTMLElement, event:MouseEvent) {
    this.setAutoCursor();
    this.removeEventListener();

    this.end.emit(this.buildDelta(event));
  }

  private onMouseMove(element:HTMLElement, event:MouseEvent) {
    event.preventDefault();
    event.stopPropagation();

    this.oldX = this.newX;
    this.oldY = this.newY;

    this.newX = event.clientX || event.pageX;
    this.newY = event.clientY || event.pageY;

    this.move.emit(this.buildDelta(event));
  }

  // Necessary to encapsulate this to be able to remove the event listener later
  private bindEventListener(event:MouseEvent) {
    this.mouseMoveHandler = this.onMouseMove.bind(this, event.currentTarget);
    this.mouseUpHandler = this.onMouseUp.bind(this, event.currentTarget);

    window.addEventListener('mousemove', this.mouseMoveHandler);
    window.addEventListener('touchmove', this.mouseMoveHandler);
    window.addEventListener('mouseup', this.mouseUpHandler);
  }

  private removeEventListener() {
    window.addEventListener('touchmove', this.mouseMoveHandler);
    window.removeEventListener('mousemove', this.mouseMoveHandler);
    window.removeEventListener('mouseup', this.mouseUpHandler);
  }

  private setResizeCursor() {
    DomHelpers.setBodyCursor(this.cursorClass, 'important');
  }

  private setAutoCursor() {
    DomHelpers.setBodyCursor('auto');
  }

  private buildDelta(event:MouseEvent):ResizeDelta {
    return {
      origin: event,
      absolute: {
        x: this.newX - this.startX,
        y: this.newY - this.startY,
      },
      relative: {
        x: this.newX - this.oldX,
        y: this.newY - this.oldX,
      }
    };
  }
}
