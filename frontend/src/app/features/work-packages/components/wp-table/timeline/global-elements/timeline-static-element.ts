import { TimelineViewParameters } from "../wp-timeline";
export const timelineStaticElementCssClassname = "wp-timeline--static-element";

export abstract class TimelineStaticElement {
  constructor() {
  }

  /**
   * Render the static element according to the current ViewParameters
   * @param vp Current timeline view paraemters
   * @returns {HTMLElement} The finished static element
   */
  public render(vp:TimelineViewParameters):HTMLElement {
    const elem = document.createElement("div");
    elem.id = this.identifier;
    elem.classList.add(...this.classNames);

    return this.finishElement(elem, vp);
  }

  protected abstract finishElement(elem:HTMLElement, vp:TimelineViewParameters):HTMLElement;

  public abstract get identifier():string;

  public get classNames():string[] {
    return [timelineStaticElementCssClassname];
  }
}
