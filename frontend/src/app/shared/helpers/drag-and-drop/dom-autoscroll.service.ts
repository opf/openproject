import { createPointCB, getClientRect as getRect, pointInside } from 'dom-plane';

export class DomAutoscrollService {
  public elements:Element[];
  public scrolling:boolean;
  public down = false;
  public scrollWhenOutside:boolean;
  public autoScroll:() => boolean;
  public maxSpeed:number;
  public margin:number;
  public animationFrame:number;
  public windowAnimationFrame:number;
  public current:HTMLElement[];
  public outerScrollContainer:HTMLElement;
  public point:any;
  public pointCB:any;

  constructor(elements:Element[],
    params:any) {
    this.elements = elements;
    this.scrollWhenOutside = params.scrollWhenOutside || false;
    this.maxSpeed = params.maxSpeed || 5;
    this.margin = params.margin || 10;
    this.scrollWhenOutside = params.scrollWhenOutside || false;
    this.autoScroll = params.autoScroll;
    this.point = {};
    this.pointCB = createPointCB(this.point);

    this.init();
  }

  public init() {
    jQuery(window).on('mousemove.domautoscroll touchmove.domautoscroll', (evt:any) => {
      if (this.down) {
        this.pointCB(evt);
        this.onMove(evt);
      }
    });
    jQuery(window).on('mousedown.domautoscroll touchstart.domautoscroll', () => this.down = true);
    jQuery(window).on('mouseup.domautoscroll touchend.domautoscroll', () => this.onUp());
    jQuery(window).on('scroll.domautoscroll', (evt:any) => this.setScroll(evt));
  }

  public destroy() {
    jQuery(window).off('.domautoscroll');

    this.elements = [];
    this.cleanAnimation();
  }

  public add(el:Element|Element[]) {
    if (Array.isArray(el)) {
      this.elements = this.elements.concat(el);

      // Remove duplicates
      this.elements = Array.from(new Set(this.elements));
    } else {
      this.elements.push(el);
    }
  }

  public onUp() {
    this.down = false;
    cancelAnimationFrame(this.animationFrame);
    cancelAnimationFrame(this.windowAnimationFrame);
  }

  public setScroll(e:any) {
    for (let i = 0; i < this.elements.length; i++) {
      if (this.elements[i] === e.target) {
        this.scrolling = true;
        break;
      }
    }

    if (this.scrolling) {
      requestAnimationFrame(() => this.scrolling = false);
    }
  }

  public cleanAnimation() {
    cancelAnimationFrame(this.animationFrame);
    cancelAnimationFrame(this.windowAnimationFrame);
  }

  public getTarget(target:HTMLElement):HTMLElement[] {
    if (!target) {
      return [];
    }

    const results = [];
    if (this.elements.includes(target)) {
      results.push(target);
    }

    let targetObject = target;
    while (targetObject = targetObject.parentNode as HTMLElement) {
      if (this.elements.includes(targetObject)) {
        results.push(targetObject);
      }
    }

    return results;
  }

  public getElementsUnderPoint():HTMLElement[] {
    const underPoint = [];

    for (var i = 0; i < this.elements.length; i++) {
      if (this.inside(this.point, this.elements[i])) {
        underPoint.push(this.elements[i] as HTMLElement);
      }
    }

    return underPoint;
  }

  public onMove(event:any) {
    if (!this.autoScroll()) {
      return;
    }

    if (event.dispatched) {
      return;
    }

    let target = [] as HTMLElement[];
    if (event.target !== null) {
      target.push(event.target as HTMLElement);
    }
    const body = document.body;

    if (target.length > 0 && target[0].parentNode === body) {
      //The special condition to improve speed.
      target = this.getElementsUnderPoint();
    } else {
      target = this.getTarget(target[0]);

      if (target.length === 0) {
        target = this.getElementsUnderPoint();
      }
    }

    this.current = target;

    if (this.current.length === 0) {
      this.current = [this.outerScrollContainer];
    }

    cancelAnimationFrame(this.animationFrame);
    this.animationFrame = requestAnimationFrame(this.scrollTick.bind(this));
  }

  public setOuterScrollContainer(el:HTMLElement) {
    this.outerScrollContainer = el;
  }

  public scrollTick() {
    if (this.current.length === 0) {
      return;
    }

    this.current.forEach((e?:Element) => {
      if (e) {
        this.scrollAutomatically(e);
      }
    });

    cancelAnimationFrame(this.animationFrame);
    this.animationFrame = requestAnimationFrame(this.scrollTick.bind(this));

  }


  public scrollAutomatically(el:Element) {
    const rect = getRect(el);
    let scrollx:number;
    let scrolly:number;

    if (this.point.x < rect.left + this.margin) {
      scrollx = -this.maxSpeed;
    } else if (this.point.x > rect.right - this.margin) {
      scrollx = this.maxSpeed;
    } else {
      scrollx = 0;
    }

    if (this.point.y < rect.top + this.margin) {
      scrolly = -this.maxSpeed;
    } else if (this.point.y > rect.bottom - this.margin) {
      scrolly = this.maxSpeed;
    } else {
      scrolly = 0;
    }

    setTimeout(() => {
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
    } else {
      el.scrollTop += amount;
    }
  }

  public scrollX(el:any, amount:number) {
    if (el === window) {
      window.scrollTo(el.pageXOffset + amount, el.pageYOffset);
    } else {
      el.scrollLeft += amount;
    }
  }

  public inside(point:any, el:Element, rect?:any) {
    if (!rect) {
      return pointInside(point, el);
    } else {
      return (point.y > rect.top && point.y < rect.bottom &&
        point.x > rect.left && point.x < rect.right);
    }
  }
}

