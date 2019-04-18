import {Inject, Injectable, OnDestroy} from "@angular/core";
import {DOCUMENT} from "@angular/common";
import {DragAndDropHelpers} from "core-app/modules/boards/drag-and-drop/drag-and-drop.helpers";
import {DomAutoscrollService} from "core-app/modules/common/drag-and-drop/dom-autoscroll.service";


export interface DragMember {
  dragContainer:HTMLElement;
  scrollContainers:HTMLElement[];
  /** Whether this element moves */
  moves:(element:HTMLElement, fromContainer:HTMLElement, handle:HTMLElement, sibling?:HTMLElement|null) => boolean;
  /** Move element in container */
  onMoved:(row:HTMLElement, target:any, source:HTMLElement, sibling:HTMLElement|null) => void;
  /** Add element to this container */
  onAdded:(row:HTMLElement, target:any, source:HTMLElement, sibling:HTMLElement|null) => Promise<boolean>;
  /** Remove element from this container */
  onRemoved:(row:HTMLElement, target:any, source:HTMLElement, sibling:HTMLElement|null) => void;
}

@Injectable()
export class DragAndDropService implements OnDestroy {

  public drake:dragula.Drake|null = null;

  public members:DragMember[] = [];

  private autoscroll:any;

  private escapeListener = (evt:KeyboardEvent) => {
    if (this.drake && evt.key === 'Escape') {
      this.drake.cancel(true);
    }
  };

  constructor(@Inject(DOCUMENT) private document:Document) {
    this.document.documentElement.addEventListener('keydown', this.escapeListener);

  }

  ngOnDestroy():void {
    this.document.documentElement.removeEventListener('keydown', this.escapeListener);
    this.autoscroll && this.autoscroll.destroy();
  }

  public remove(container:HTMLElement) {
    if (this.initialized) {
      _.remove(this.drake!.containers, (el) => el === container);
      _.remove(this.members, (el) => el.dragContainer === container);
    }
  }

  public member(container:HTMLElement):DragMember|undefined {
    return _.find(this.members, el => el.dragContainer === container);
  }

  public get initialized() {
    return this.drake !== null;
  }

  public register(member:DragMember) {
    this.members.push(member);
    const dragContainer = member.dragContainer;

    if (this.autoscroll) {
      this.autoscroll.add(dragContainer);
    } else {
      this.setupAutoscroll([dragContainer]);
    }

    if (this.drake === null) {
      this.initializeDrake([dragContainer]);
    } else {
      this.drake.containers.push(dragContainer);
    }
  }

  public addScrollContainer(el:Element) {
    if (this.autoscroll) {
      this.autoscroll.add(el);
    } else {
      this.setupAutoscroll([el]);
    }
    this.autoscroll.setOuterScrollContainer(el);
  }

  protected setupAutoscroll(containers:Element[]) {
    // Setup autoscroll
    this.autoscroll = new DomAutoscrollService(
      containers,
      {
        margin: 100,
        maxSpeed: 10,
        scrollWhenOutside: true,
        autoScroll: () => this.drake && this.drake.dragging
      });
  }

  protected initializeDrake(containers:Element[]) {
    this.drake = dragula(containers, {
      moves: (el:any, container:any, handle:any, sibling:any) => {

        let result = false;
        this.members.forEach(member => {
          if (member.dragContainer === container) {
            result = member.moves(el, container, handle, sibling);
            return;
          }
        });

        return result;
      },
      accepts: () => true,
      invalid: () => false,
      direction: 'vertical',             // Y axis is considered when determining where an element would be dropped
      copy: false,                       // elements are moved by default, not copied
      revertOnSpill: true,               // spilling will put the element back where it was dragged from, if this is true
      removeOnSpill: false,              // spilling will `.remove` the element, if this is true
      mirrorContainer: document.body,    // set the element that gets mirror elements appended
      ignoreInputTextSelection: true     // allows users to select input text, see details below
    });

    this.drake.on('drag', (el:HTMLElement, source:HTMLElement) => {
      el.dataset.sourceIndex = DragAndDropHelpers.findIndex(el).toString();
    });

    this.drake.on('over', (el:HTMLElement, container:HTMLElement) => {
      container.classList.add('-drop-zone');
    });

    this.drake.on('out', (el:HTMLElement, container:HTMLElement) => {
      container.classList.remove('-drop-zone');
    });

    this.drake.on('drop', async (el:HTMLElement, target:HTMLElement, source:HTMLElement, sibling:HTMLElement|null) => {
      try {
        await this.handleDrop(el, target, source, sibling);
      } catch (e) {
        console.error("Failed to handle drop of %O", el);
      }
    });
  }

  private async handleDrop(el:HTMLElement, target:HTMLElement, source:HTMLElement, sibling:HTMLElement|null) {
    const to = this.member(target);
    const from = this.member(source);

    if (!(to && from)) {
      return;
    }

    if (to === from) {
      return to.onMoved(el, target, source, sibling);
    }

    const result = await to.onAdded(el, target, source, sibling);

    if (result) {
      from.onRemoved(el, target, source, sibling);
    } else {
      // Restore element in from container
      DragAndDropHelpers.reinsert(el, el.dataset.sourceIndex || -1, source);
    }
  }
}
