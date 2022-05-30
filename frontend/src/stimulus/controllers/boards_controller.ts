import { Controller } from '@hotwired/stimulus';
import {
  HttpClient,
  HttpHeaders,
} from '@angular/common/http';
import { buildDelta } from 'core-app/shared/helpers/drag-and-drop/reorder-delta-builder';

export default class extends Controller {
  http:HttpClient;

  initialize() {
    window
      .OpenProject
      .getPluginContext()
      .then((context) => {
        this.http = context.injector.get(HttpClient);
      });
  }

  connect() {
    // Make custom fields draggable
    // eslint-disable-next-line no-undef
    const drake = dragula([this.element], {
      isContainer: (el:HTMLElement) => el.classList.contains('op-hot-list--container'),
      moves: function (el, source, handle, sibling) {
        return !!handle?.closest('.op-wp-single-card');
      },
      accepts: (el:HTMLElement, container:HTMLElement) => container.classList.contains('op-hot-list--container'),
      invalid: () => false,
      direction: 'vertical',
      copy: false,
      copySortSource: false,
      revertOnSpill: true,
      removeOnSpill: false,
      ignoreInputTextSelection: true,
    });

    drake.on('drop', (el:HTMLElement, target:HTMLElement, source:HTMLElement, sibling:HTMLElement) => {
      const headers = new HttpHeaders({ 'Content-Type': 'application/json' });
      const children = Array.from(el.parentElement?.children || []);
      const order:string[] = children.map((c:HTMLElement) => c.dataset.id as string);
      const positions:{[wpId:string]:number} = {};
      const index = children.findIndex(c => el === c);
      children.forEach((c:HTMLElement) => {
        if (c !== el) {
          positions[c.dataset.id as string] = parseInt(c.dataset.position as string, 2);
        }
      });

      const wpId = el.dataset.id as string;
      const delta = buildDelta(order, positions, wpId, index, null);

      this
        .http
        .post(
          `/hot_boards/${this.boardId}/delta`,
          { delta },
          { withCredentials: true, headers }
        )
        .subscribe();
    });
  }

  get boardId():string {
    return (this.element as HTMLElement).dataset.boardId as string;
  }
}
