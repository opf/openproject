//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { NgSelectModule } from '@ng-select/ng-select';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AlternativeSearchService } from 'core-app/shared/components/work-packages/alternative-search.service';
import {
  OpSortableListsItemDirective,
} from 'core-app/shared/directives/sortable-lists/sortable-lists-item.directive';
import { OpSortableListsDirective } from 'core-app/shared/directives/sortable-lists/sortable-lists.directive';
import {
  NativeDragSimulation,
  centerOf,
  towardsEdgeOf,
} from 'core-common/drag-and-drop/testing/native-drag-simulation';
import { type Edge } from 'core-common/drag-and-drop/reorder';
import { type SortableListsDropEvent } from 'core-app/shared/directives/sortable-lists/sortable-lists.directive';
import { DraggableAutocompleteComponent, DraggableOption } from './draggable-autocomplete.component';

// `component.reorder` only reads `sourceId`/`targetId`/`edge`; the
// transaction bookkeeping fields are irrelevant to these unit tests but
// still required by the type, so this factory fills them with inert
// defaults.
function dropEvent(overrides:{ sourceId:string; targetId:string; edge:Edge }):SortableListsDropEvent {
  return {
    transactionId: 'test-transaction',
    sourceListId: 'test-list',
    axis: 'vertical',
    complete: () => undefined,
    ...overrides,
  };
}

describe('DraggableAutocompleteComponent', () => {
  let fixture:ComponentFixture<DraggableAutocompleteComponent>;
  let component:DraggableAutocompleteComponent;

  const a:DraggableOption = { id: 'a', name: 'Alpha' };
  const b:DraggableOption = { id: 'b', name: 'Bravo' };
  const c:DraggableOption = { id: 'c', name: 'Charlie' };

  const i18nStub = { t: (_key:string) => 'label' };
  const alternativeSearchStub = { searchFunction: () => true };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [DraggableAutocompleteComponent],
      imports: [NgSelectModule, OpSortableListsDirective, OpSortableListsItemDirective],
      providers: [
        { provide: I18nService, useValue: i18nStub },
        { provide: AlternativeSearchService, useValue: alternativeSearchStub },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(DraggableAutocompleteComponent);
    component = fixture.componentInstance;
    mountInScrollableAncestor(fixture);

    // Avoid focusing the ng-select during ngAfterViewInit in the test DOM.
    component.autofocus = false;
    component.options = [a, b, c];
    component.selected = [a, b];
  });

  afterEach(() => {
    document.body.replaceChildren();
  });

  // Real embeddings (a Primer Dialog or a scrolling page) give the collapsed
  // sortable root's closest-scrollable-ancestor fallback something to find.
  // Mirrors that here — attached to the document, like drag simulation
  // already requires for `elementFromPoint` — so registering autoscroll
  // doesn't warn about the component's own `overflow: visible` root.
  function mountInScrollableAncestor(of:ComponentFixture<DraggableAutocompleteComponent>):void {
    const scrollWrapper = document.createElement('div');
    scrollWrapper.style.overflow = 'auto';
    scrollWrapper.style.height = '400px';
    scrollWrapper.appendChild(of.nativeElement);
    document.body.appendChild(scrollWrapper);
  }

  function chips() {
    return fixture.debugElement.queryAll(By.css('.op-draggable-autocomplete--item'));
  }

  function chipTexts() {
    return chips().map((chip) => {
      const text = chip.query(By.css('.op-draggable-autocomplete--item-text')).nativeElement as HTMLElement;
      return text.textContent?.trim() ?? '';
    });
  }

  it('creates', () => {
    fixture.detectChanges();

    expect(component).toBeTruthy();
  });

  it('renders a chip per selected option in order', () => {
    fixture.detectChanges();

    expect(chipTexts()).toEqual(['Alpha', 'Bravo']);
  });

  it('exposes only the not-yet-selected options as available', () => {
    fixture.detectChanges();

    expect(component.availableOptions).toEqual([c]);
  });

  it('adds an option on select, updating available options and emitting', () => {
    fixture.detectChanges();
    const emitted:DraggableOption[][] = [];
    component.onChange.subscribe((value) => emitted.push(value));

    component.select(c);

    expect(component.selected).toEqual([a, b, c]);
    expect(component.availableOptions).toEqual([]);
    expect(emitted).toEqual([[a, b, c]]);
  });

  it('removes an option, updating available options and emitting', () => {
    fixture.detectChanges();
    const emitted:DraggableOption[][] = [];
    component.onChange.subscribe((value) => emitted.push(value));

    component.remove(a);

    expect(component.selected).toEqual([b]);
    expect(component.availableOptions).toEqual([a, c]);
    expect(emitted).toEqual([[b]]);
  });

  it('does not render a remove control for protected options', () => {
    component.protected = [a];
    fixture.detectChanges();

    expect(component.isRemovable(a)).toBe(false);
    expect(component.isRemovable(b)).toBe(true);

    const removeControls = fixture.debugElement.queryAll(By.css('.op-draggable-autocomplete--remove-item'));

    expect(removeControls.length).toBe(1);
  });

  it('renders a single hidden input with a space-joined value for scalar names', () => {
    component.name = 'columns';
    fixture.detectChanges();

    expect(component.isArrayOfValues).toBe(false);
    expect(component.hiddenValue).toBe('a b');

    const hidden = fixture.debugElement.queryAll(By.css('input[type=hidden]'));

    expect(hidden.length).toBe(1);
    expect((hidden[0].nativeElement as HTMLInputElement).value).toBe('a b');
  });

  it('renders one hidden input per value for array names', () => {
    component.name = 'columns[]';
    fixture.detectChanges();

    expect(component.isArrayOfValues).toBe(true);
    expect(component.hiddenValues).toEqual(['a', 'b']);

    const hidden = fixture.debugElement.queryAll(By.css('input[type=hidden]'));

    expect(hidden.map((input) => (input.nativeElement as HTMLInputElement).value)).toEqual(['a', 'b']);
  });

  it('flags an error only when required and nothing is selected', () => {
    component.required = true;
    component.selected = [];
    fixture.detectChanges();

    expect(component.hasError).toBe(true);

    component.selected = [a];

    expect(component.hasError).toBe(false);
  });

  it('labels the remove button with the option name', () => {
    fixture.detectChanges();

    const removeButton = fixture.debugElement.query(By.css('.op-draggable-autocomplete--remove-item'))
      .nativeElement as HTMLButtonElement;

    expect(removeButton.tagName).toBe('BUTTON');
    expect(removeButton.getAttribute('aria-label')).toBe('label');
  });

  describe('reordering through the sortable-lists drop output', () => {
    beforeEach(() => {
      component.selected = [a, b, c];
      fixture.detectChanges();
    });

    it('moves an item before the target on a left-edge drop', () => {
      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      component.reorder(dropEvent({ sourceId: 'c', targetId: 'a', edge: 'left' }));

      expect(component.selected).toEqual([c, a, b]);
      expect(emitted).toEqual([[c, a, b]]);
    });

    it('moves an item after the target on a right-edge drop', () => {
      component.reorder(dropEvent({ sourceId: 'a', targetId: 'c', edge: 'right' }));

      expect(component.selected).toEqual([b, c, a]);
    });

    it('does not emit for an adjacent no-op drop', () => {
      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      component.reorder(dropEvent({ sourceId: 'a', targetId: 'b', edge: 'left' }));

      expect(component.selected).toEqual([a, b, c]);
      expect(emitted).toEqual([]);
    });

    it('does not emit when either id is unknown', () => {
      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      component.reorder(dropEvent({ sourceId: 'missing', targetId: 'a', edge: 'left' }));
      component.reorder(dropEvent({ sourceId: 'a', targetId: 'missing', edge: 'left' }));

      expect(component.selected).toEqual([a, b, c]);
      expect(emitted).toEqual([]);
    });
  });

  describe('dragging chips', () => {
    function chipElements(of:ComponentFixture<DraggableAutocompleteComponent>):HTMLElement[] {
      return Array.from((of.nativeElement as HTMLElement).querySelectorAll('.op-draggable-autocomplete--item'));
    }

    it('reorders the selection through a native drag', async () => {
      component.selected = [a, b, c];
      // The collapsed root's closest-scrollable-ancestor fallback (see
      // `mountInScrollableAncestor`) must resolve to a real scroll target,
      // not the component's own `overflow: visible` root — otherwise
      // Pragmatic's autoscroll adapter warns on every registration.
      const warnSpy = vi.spyOn(console, 'warn');
      fixture.detectChanges();

      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      const [first, , third] = chipElements(fixture);
      const simulation = new NativeDragSimulation(third);

      await simulation.start();
      await simulation.drop(first, towardsEdgeOf(first, 'left'));

      expect(component.selected).toEqual([c, a, b]);
      expect(emitted).toEqual([[c, a, b]]);
      expect(warnSpy).not.toHaveBeenCalledWith(
        expect.stringContaining('not to be scrollable'),
        expect.anything(),
      );
    });

    it('cannot mutate or emit from another autocompleter with overlapping ids', async () => {
      fixture.detectChanges();

      const otherFixture = TestBed.createComponent(DraggableAutocompleteComponent);
      const otherComponent = otherFixture.componentInstance;
      otherComponent.autofocus = false;
      otherComponent.options = [a, b, c];
      otherComponent.selected = [a, b];
      mountInScrollableAncestor(otherFixture);
      otherFixture.detectChanges();

      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));
      const otherEmitted:DraggableOption[][] = [];
      otherComponent.onChange.subscribe((value) => otherEmitted.push(value));

      const source = chipElements(fixture)[0];
      const foreignTarget = chipElements(otherFixture)[1];
      const simulation = new NativeDragSimulation(source);

      await simulation.start();
      await simulation.drop(foreignTarget, towardsEdgeOf(foreignTarget, 'right'));

      expect(component.selected).toEqual([a, b]);
      expect(otherComponent.selected).toEqual([a, b]);
      expect(emitted).toEqual([]);
      expect(otherEmitted).toEqual([]);
    });

    it('drops beyond the last chip to append the dragged item at the end', async () => {
      component.selected = [a, b, c];
      fixture.detectChanges();

      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));
      const reorderSpy = vi.spyOn(component, 'reorder');

      const container = (fixture.nativeElement as HTMLElement)
        .querySelector<HTMLElement>('.op-draggable-autocomplete--selected')!;
      const [first, , third] = chipElements(fixture);
      const simulation = new NativeDragSimulation(first);
      const lastRect = third.getBoundingClientRect();
      const midSpanPoint = centerOf(third);

      await simulation.start();
      // Same handoff the engine relies on to resolve a container-append
      // drop: pass over the last item first, then move past its far edge
      // while still within the list container.
      await simulation.dragOver(third, midSpanPoint);
      await simulation.dragOver(container, midSpanPoint);

      const beyondSpan = { x: lastRect.right + 30, y: midSpanPoint.y };
      await simulation.dragOver(container, beyondSpan);
      await simulation.drop(container, beyondSpan);

      expect(component.selected).toEqual([b, c, a]);
      expect(emitted).toEqual([[b, c, a]]);
      expect(reorderSpy.mock.calls[0][0].targetId).toBeNull();
    });

    it('does not start a drag when initiated on a remove button', async () => {
      component.selected = [a, b, c];
      fixture.detectChanges();

      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      const [first, , third] = chipElements(fixture);
      const removeButton = first.querySelector<HTMLElement>('.op-draggable-autocomplete--remove-item')!;
      const simulation = new NativeDragSimulation(first);

      await simulation.start(centerOf(removeButton));
      fixture.detectChanges();

      expect(first.hasAttribute('data-dragging')).toBe(false);

      await simulation.drop(third, towardsEdgeOf(third, 'left'));

      expect(component.selected).toEqual([a, b, c]);
      expect(emitted).toEqual([]);
    });

    it('applies two consecutive drags without the second being blocked', async () => {
      component.selected = [a, b, c];
      fixture.detectChanges();

      const firstDrag = new NativeDragSimulation(chipElements(fixture)[2]);
      await firstDrag.start();
      await firstDrag.drop(chipElements(fixture)[0], towardsEdgeOf(chipElements(fixture)[0], 'left'));

      // [a, b, c] -> [c, a, b]: same move already proven correct above; the
      // point of this case is that a second drag right after still works,
      // which only holds if the first transaction was completed.
      expect(component.selected).toEqual([c, a, b]);

      fixture.detectChanges();
      const secondDrag = new NativeDragSimulation(chipElements(fixture)[0]);
      await secondDrag.start();
      await secondDrag.drop(chipElements(fixture)[2], towardsEdgeOf(chipElements(fixture)[2], 'left'));

      // [c, a, b] -> [a, c, b]: the exact result matters less than the fact
      // that it changed at all — this only holds if the first transaction
      // completed and released the engine for a second drag.
      expect(component.selected).toEqual([a, c, b]);
    });
  });
});
