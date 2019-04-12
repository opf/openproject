import {createPointCB, getClientRect as getRect, pointInside} from 'dom-plane';

export class DomAutoscrollService {
  public elements:(Element|Window)[];
  public scrolling:boolean;
  public down:boolean = false;
  public scrollWhenOutside:boolean;
  public autoScroll:() => boolean;
  public maxSpeed:number;
  public margin:number;
  public animationFrame:number;
  public windowAnimationFrame:number;
  public current:HTMLElement[];
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

    this.init();
  }

  public init() {
    window.addEventListener('mousemove', this.pointCB, false);
    window.addEventListener('touchmove', this.pointCB, false);

    this.hasWindow = !!_.find(this.elements, (element) => element === window);

    window.addEventListener('mousemove', this.onMove.bind(this), false);
    window.addEventListener('touchmove', this.onMove.bind(this), false);
    window.addEventListener('mouseup', this.onUp.bind(this), false);

    window.addEventListener('scroll', this.setScroll.bind(this), true);
  }
  
  public destroy() {
    window.removeEventListener('mousemove', this.pointCB, false);
    window.removeEventListener('touchmove', this.pointCB, false);

    window.removeEventListener('mousemove', this.onMove, false);
    window.removeEventListener('touchmove', this.onMove, false);

    window.addEventListener('mouseup', this.onUp, false);

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

  public onUp() {
    cancelAnimationFrame(this.animationFrame);
    cancelAnimationFrame(this.windowAnimationFrame);
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

  public cleanAnimation() {
    cancelAnimationFrame(this.animationFrame);
    cancelAnimationFrame(this.windowAnimationFrame);
  }

  public getTarget(target:HTMLElement):HTMLElement[] {
    if (!target) {
      return [];
    }

    let results = [];

    // if (this.current === target) {
    //   results.push(target);
    // } else
    if (this.elements.includes(target)) {
      results.push(target);
    }

    let targetObject = target;
    while(targetObject = targetObject.parentNode as HTMLElement) {
      if (this.elements.includes(targetObject)) {
        results.push(targetObject);
      }
    }

    return results;
  }

  public getElementsUnderPoint():HTMLElement[] {
    let underPoint = [];

    for(var i = 0; i < this.elements.length; i++) {
      if (this.inside(this.point, this.elements[i])) {
        underPoint.push(this.elements[i] as HTMLElement);
      }
    }

    return underPoint;
  }

  public onMove(event:MouseEvent) {

    if (!this.autoScroll()) return;

    if ((event as any).dispatched) { return; }

    let target = [] as HTMLElement[];
    if (event.target !== null) {
      target.push(event.target as HTMLElement);
    }
    let body = document.body;

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

    if (this.hasWindow) {
      cancelAnimationFrame(this.windowAnimationFrame);
      this.windowAnimationFrame = requestAnimationFrame(this.scrollWindow.bind(this));
    }


    if (this.current.length === 0) {
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

    if (this.current.length === 0) {
      return;
    }

    this.current.forEach((e) => {
      console.log('automatically: %O', e);
      this.scrollAutomatically(e);
    });

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
        console.log('Scroll Y: %O %O', el, scrolly);
        this.scrollY(el, scrolly);
      }

      if (scrollx) {
        console.log('Scroll X: %O %O', el, scrollx);
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

  public inside(point:any, el:Element|Window, rect?:any) {
    if (!rect) {
      return pointInside(point, el);
    } else {
      return (point.y > rect.top && point.y < rect.bottom &&
        point.x > rect.left && point.x < rect.right);
    }
  }
}

