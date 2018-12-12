import {
  Component,
  OnDestroy,
  EventEmitter,
  Output,
  Input,
  HostListener} from "@angular/core";


export interface ResizeDelta {
  x:number;
  y:number;
}

@Component({
  selector: 'resizer',
  templateUrl: './resizer.component.html'
})
export class ResizerComponent implements OnDestroy {
  private oldX:number;
  private oldY:number;
  private newX:number;
  private newY:number;
  private mouseMoveHandler:EventListener;
  private mouseUpHandler:EventListener;
  private resizing = false;

  @Output() end:EventEmitter<ResizeDelta> = new EventEmitter();
  @Output() start:EventEmitter<null> = new EventEmitter();
  @Output() move:EventEmitter<ResizeDelta> = new EventEmitter();

  @Input() customHandler = false;
  @Input() cursorClass = 'nwse-resize';

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
      this.oldX = event.clientX;
      this.oldY = event.clientY;

      this.newX = event.clientX;
      this.newY = event.clientY;

      this.resizing = true;

      this.setResizeCursor();
      this.bindEventListener(event);
    }

    this.start.emit();
  }

  private onMouseUp(element:HTMLElement, event:MouseEvent) {
    this.setAutoCursor();
    this.removeEventListener();

    let deltas = {
      x: this.newX - this.oldX,
      y: this.newY - this.oldY
    };

    this.end.emit(deltas);
  }

  private onMouseMove(element:HTMLElement, event:MouseEvent) {
    event.preventDefault();
    event.stopPropagation();

    this.newX = event.clientX;
    this.newY = event.clientY;

    let deltas = {
      x: this.newX - this.oldX,
      y: this.newY - this.oldY
    };

    this.move.emit(deltas);
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
    this.setCursor(`${this.cursorClass} !important`);
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
