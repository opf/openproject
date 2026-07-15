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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
  towardsEdgeOf,
} from 'core-common/drag-and-drop/testing/native-drag-simulation';
import { DraggableAutocompleteComponent, DraggableOption } from './draggable-autocomplete.component';

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

    // Avoid focusing the ng-select during ngAfterViewInit in the test DOM.
    component.autofocus = false;
    component.options = [a, b, c];
    component.selected = [a, b];
  });

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

      component.reorder({ sourceId: 'c', targetId: 'a', edge: 'left' });

      expect(component.selected).toEqual([c, a, b]);
      expect(emitted).toEqual([[c, a, b]]);
    });

    it('moves an item after the target on a right-edge drop', () => {
      component.reorder({ sourceId: 'a', targetId: 'c', edge: 'right' });

      expect(component.selected).toEqual([b, c, a]);
    });

    it('does not emit for an adjacent no-op drop', () => {
      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      component.reorder({ sourceId: 'a', targetId: 'b', edge: 'left' });

      expect(component.selected).toEqual([a, b, c]);
      expect(emitted).toEqual([]);
    });

    it('does not emit when either id is unknown', () => {
      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      component.reorder({ sourceId: 'missing', targetId: 'a', edge: 'left' });
      component.reorder({ sourceId: 'a', targetId: 'missing', edge: 'left' });

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
      fixture.detectChanges();

      const emitted:DraggableOption[][] = [];
      component.onChange.subscribe((value) => emitted.push(value));

      const [first, , third] = chipElements(fixture);
      const simulation = new NativeDragSimulation(third);

      await simulation.start();
      await simulation.drop(first, towardsEdgeOf(first, 'left'));

      expect(component.selected).toEqual([c, a, b]);
      expect(emitted).toEqual([[c, a, b]]);
    });

    it('cannot mutate or emit from another autocompleter with overlapping ids', async () => {
      fixture.detectChanges();

      const otherFixture = TestBed.createComponent(DraggableAutocompleteComponent);
      const otherComponent = otherFixture.componentInstance;
      otherComponent.autofocus = false;
      otherComponent.options = [a, b, c];
      otherComponent.selected = [a, b];
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
  });
});
