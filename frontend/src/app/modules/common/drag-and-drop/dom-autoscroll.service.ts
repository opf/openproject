import {OnDestroy, OnInit} from "@angular/core";
import {
  createPointCB,
  getClientRect as getRect,
  pointInside
} from 'dom-plane';

export class DomAutoscrollService implements OnInit, OnDestroy {
  public elements:(Element|Window)[];
  public scrolling:boolean;
  public down:boolean = false;
  public scrollWhenOutside:boolean;
  public autoScroll:boolean;
  public maxSpeed:number;
  public margin:number;
  public animationFrame:number;
  public windowAnimationFrame:number;
  public current:any;
  public point:any;
  public pointCB:any;
  public hasWindow:boolean;

  constructor(elements:(Element|Window)[],
              params:any) {
    this.elements = elements;
    this.scrollWhenOutside = params.scrollWhenOutside || false;
    this.maxSpeed = params.maxSpeed || 5;
    this.margin = params.margin || 10;
    this.scrollWhenOutside = params.scrollWhenOutside || false;
    this.autoScroll = params.autoScroll;
    this.point = {};
    this.pointCB = createPointCB(this.point);

    this.ngOnInit();
  }


  ngOnInit() {
    window.addEventListener('mousemove', this.pointCB, false);
    window.addEventListener('touchmove', this.pointCB, false);

    this.hasWindow = !!_.find(this.elements, (element) => element === window);


    window.addEventListener('mousedown', this.onDown.bind(this), false);
    window.addEventListener('touchstart', this.onDown.bind(this), false);
    window.addEventListener('mouseup', this.onUp.bind(this), false);
    window.addEventListener('touchend', this.onUp.bind(this), false);

    /*
    IE does not trigger mouseup event when scrolling.
    It is a known issue that Microsoft won't fix.
    https://connect.microsoft.com/IE/feedback/details/783058/scrollbar-trigger-mousedown-but-not-mouseup
    IE supports pointer events instead
    */
    window.addEventListener('pointerup', this.onUp.bind(this), false);

    window.addEventListener('mousemove', this.onMove.bind(this), false);
    window.addEventListener('touchmove', this.onMove.bind(this), false);

    window.addEventListener('mouseleave', this.onMouseOut.bind(this), false);

    window.addEventListener('scroll', this.setScroll.bind(this), true);



  }
  
  ngOnDestroy() {
    window.removeEventListener('mousemove', this.pointCB, false);
    window.removeEventListener('touchmove', this.pointCB, false);
    window.removeEventListener('mousedown', this.onDown, false);
    window.removeEventListener('touchstart', this.onDown, false);
    window.removeEventListener('mouseup', this.onUp, false);
    window.removeEventListener('touchend', this.onUp, false);
    window.removeEventListener('pointerup', this.onUp, false);
    window.removeEventListener('mouseleave', this.onMouseOut, false);

    window.removeEventListener('mousemove', this.onMove, false);
    window.removeEventListener('touchmove', this.onMove, false);

    window.removeEventListener('scroll', this.setScroll, true);
    this.elements = [];
    this.cleanAnimation();
  }

  public add(el:Element) {
    this.elements.push(el);
  }

  public remove(el:Element) {
    _.remove(this.elements, el);
  }

  public setScroll(e:Event) {
    for(let i = 0; i < this.elements.length; i++) {
      if (this.elements[i] === e.target) {
        this.scrolling = true;
        break;
      }
    }

    if (this.scrolling) {
      requestAnimationFrame(() => this.scrolling = false)
    }
  }

  public onDown() {
    this.down = true;
  }

  public onUp() {
    this.down = false;
    this.cleanAnimation();
  }

  public cleanAnimation() {
    cancelAnimationFrame(this.animationFrame);
    cancelAnimationFrame(this.windowAnimationFrame);
  }

  public onMouseOut() {
    this.down = false;
  }

  public getTarget(target:HTMLElement|null):HTMLElement|null {
    if (!target) {
      return null;
    }

    if (this.current === target) {
      return target;
    }

    if (this.elements.includes(target)) {
      return target;
    }

    while(target = target.parentNode as HTMLElement) {
      if (this.elements.includes(target)) {
        return target;
      }
    }

    return null;
  }

  public getElementUnderPoint():HTMLElement {
    let underPoint = null;

    for(var i = 0; i < this.elements.length; i++) {
      if (this.inside(this.point, this.elements[i])) {
        underPoint = this.elements[i];
      }
    }

    return (underPoint as HTMLElement);
  }

  public onMove(event:MouseEvent) {

    if (!this.autoScroll) return;

    if ((event as any).dispatched) { return; }

    let target = event.target as HTMLElement|null;
    let body = document.body;

    if (this.current && !this.inside(this.point, this.current)) {
      if (!this.scrollWhenOutside) {
        this.current = null;
      }
    }

    if (target && target.parentNode === body) {
      //The special condition to improve speed.
      target = this.getElementUnderPoint();
    }else{
      target = this.getTarget(target);

      if (!target) {
        target = this.getElementUnderPoint();
      }
    }


    if (target && target !== this.current) {
      this.current = target;
    }

    if (this.hasWindow) {
      cancelAnimationFrame(this.windowAnimationFrame);
      this.windowAnimationFrame = requestAnimationFrame(this.scrollWindow.bind(this));
    }


    if (!this.current) {
      return;
    }

    cancelAnimationFrame(this.animationFrame);
    this.animationFrame = requestAnimationFrame(this.scrollTick.bind(this));
  }

  public scrollWindow() {
    this.scrollAutomatically(window);

    cancelAnimationFrame(this.windowAnimationFrame);
    this.windowAnimationFrame = requestAnimationFrame(this.scrollWindow.bind(this));
  }

  public scrollTick() {

    if (!this.current) {
      return;
    }

    this.scrollAutomatically(this.current);

    cancelAnimationFrame(this.animationFrame);
    this.animationFrame = requestAnimationFrame(this.scrollTick.bind(this));

  }


  public scrollAutomatically(el:Element|Window) {
    let rect = getRect(el);
    let scrollx:number;
    let scrolly:number;

    if (this.point.x < rect.left + this.margin) {
      scrollx = Math.floor(
        Math.max(-1, (this.point.x - rect.left) / this.margin - 1) * this.maxSpeed
      );
    } else if (this.point.x > rect.right - this.margin) {
      scrollx = Math.ceil(
        Math.min(1, (this.point.x - rect.right) / this.margin + 1) * this.maxSpeed
      );
    } else {
      scrollx = 0;
    }

    if (this.point.y < rect.top + this.margin) {
      scrolly = Math.floor(
        Math.max(-1, (this.point.y - rect.top) / this.margin - 1) * this.maxSpeed
      );
    } else if (this.point.y > rect.bottom - this.margin) {
      scrolly = Math.ceil(
        Math.min(1, (this.point.y - rect.bottom) / this.margin + 1) * this.maxSpeed
      );
    } else {
      scrolly = 0;
    }

    setTimeout(()=>{

      if (scrolly) {
        this.scrollY(el, scrolly);
      }

      if (scrollx) {
        this.scrollX(el, scrollx);
      }

    });
  }

  public scrollY(el:any, amount:number) {
    if (el === window) {
      window.scrollTo(el.pageXOffset, el.pageYOffset + amount);
    }else{
      el.scrollTop += amount;
    }
  }

  public scrollX(el:any, amount:number) {
    if (el === window) {
      window.scrollTo(el.pageXOffset + amount, el.pageYOffset);
    }else{
      el.scrollLeft += amount;
    }
  }

  public inside(point:any, el:Element|Window, rect?:any) {
    if (!rect) {
      return pointInside(point, el);
    }else{
      return (point.y > rect.top && point.y < rect.bottom &&
        point.x > rect.left && point.x < rect.right);
    }
  }
}

