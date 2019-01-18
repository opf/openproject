import {Injectable} from "@angular/core";

export interface DragMember {
  container:HTMLElement;
  moves:(element:HTMLElement, fromContainer:HTMLElement, handle:HTMLElement, sibling:HTMLElement|null) => boolean;
  onMoved:(row:HTMLTableRowElement, target:any, source:HTMLTableRowElement, sibling:HTMLTableRowElement|null) => void;
  onAdded:(row:HTMLTableRowElement, target:any, source:HTMLTableRowElement, sibling:HTMLTableRowElement|null) => void;
  onRemoved:(row:HTMLTableRowElement, target:any, source:HTMLTableRowElement, sibling:HTMLTableRowElement|null) => void;
}

@Injectable()
export class DragAndDropService {

  public drake:dragula.Drake|null = null;

  public members:DragMember[] = [];

  public remove(container:HTMLElement) {
    if (this.initialized) {
      _.remove(this.drake!.containers, (el) => el === container);
      _.remove(this.members, (el) => el.container === container);
    }
  }

  public member(container:HTMLElement):DragMember|undefined {
    return _.find(this.members, el => el.container === container);
  }

  public get initialized() {
    return this.drake !== null;
  }

  public register(...members:DragMember[]) {
    this.members.push(...members);
    const containers = members.map(m => m.container);
    if (this.drake === null) {
      this.initializeDrake(containers);
    } else {
      this.drake.containers.push(...containers);
    }
  }

  protected initializeDrake(containers:any) {
    this.drake = dragula(containers, {
      moves: (el:any, container:any, handle:any, sibling:any) => {
        let result = false;
        this.members.forEach(member => {
          if (member.container === container) {
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

    this.drake.on('drop', (row:HTMLTableRowElement, target:HTMLElement, source:HTMLTableRowElement, sibling:HTMLTableRowElement|null) => {
      const to = this.member(target);
      const from = this.member(source);

      if (to && to === from) {
        return to.onMoved(row, target, source, sibling);
      }

      to && to.onAdded(row, target, source, sibling);
      from && from.onRemoved(row, target, source, sibling);
    });
  }
}
