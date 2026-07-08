// -- copyright
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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ProjectTimelineItem, ProjectTimelineGraphComponent } from './project-timeline-graph.component';

describe('ProjectTimelineGraphComponent', () => {
  const i18nStub = {
    t(key:string):string {
      return {
        'js.grid.widgets.project_timeline.tooltip_type_phase': 'Phase',
        'js.grid.widgets.project_timeline.tooltip_type_gate': 'Gate',
      }[key] ?? key;
    },
  };

  const phaseWithDates = {
    id: 1,
    definitionId: 3,
    name: 'Design',
    startDate: '2024-01-01',
    endDate: '2024-03-31',
    startGate: false,
    startGateName: null,
    finishGate: false,
    finishGateName: null,
  };

  const phaseWithGates = {
    id: 2,
    definitionId: 5,
    name: 'Build',
    startDate: '2024-04-01',
    endDate: '2024-06-30',
    startGate: true,
    startGateName: 'Build Start',
    finishGate: true,
    finishGateName: 'Build End',
  };

  const phaseWithoutDates = {
    id: 3,
    definitionId: 7,
    name: 'Undated',
    startDate: null,
    endDate: null,
    startGate: false,
    startGateName: null,
    finishGate: false,
    finishGateName: null,
  };

  let fixture:ComponentFixture<ProjectTimelineGraphComponent>;
  let component:ProjectTimelineGraphComponent;

  let buildData:(phases:unknown[]) => { items:ProjectTimelineItem[]; groups:{ id:string; content:string }[] };
  let tooltipTemplate:(item:ProjectTimelineItem) => HTMLElement|string;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ProjectTimelineGraphComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ProjectTimelineGraphComponent);
    component = fixture.componentInstance;

    // Set required input before detectChanges triggers ngAfterViewInit
    fixture.componentRef.setInput('phasesData', '[]');
    fixture.detectChanges();

    // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
    buildData = (component as any).buildData.bind(component);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
    tooltipTemplate = (component as any).tooltipTemplate.bind(component);
  });

  describe('buildData', () => {
    it('creates a range item for a phase with dates', () => {
      const { items } = buildData([phaseWithDates]);
      const item = items.find((i) => i.id === 'phase-1');

      expect(item).toBeDefined();
      expect(item!.type).toBe('range');
      expect(item!.group).toBe('lifecycle');
      expect(item!.content).toBe('Design');
      expect(item!.className).toContain('__hl_background_project_phase_definition_3');
      expect(item!.definitionId).toBe(3);
    });

    it('skips a phase without dates', () => {
      const { items } = buildData([phaseWithoutDates]);
      expect(items.find((i) => i.id === 'phase-3')).toBeUndefined();
    });

    it('creates start and finish gate items when configured', () => {
      const { items } = buildData([phaseWithGates]);

      const startGate = items.find((i) => i.id === 'gate-start-2');
      expect(startGate).toBeDefined();
      expect(startGate!.type).toBe('point');
      expect(startGate!.group).toBe('gates');
      expect(startGate!.title).toBe('Build Start');
      expect(startGate!.className).toContain('op-timeline-gate');

      const finishGate = items.find((i) => i.id === 'gate-finish-2');
      expect(finishGate).toBeDefined();
      expect(finishGate!.title).toBe('Build End');
    });

    it('does not create gate items when gates are disabled', () => {
      const { items } = buildData([phaseWithDates]);
      expect(items.find((i) => i.id === 'gate-start-1')).toBeUndefined();
      expect(items.find((i) => i.id === 'gate-finish-1')).toBeUndefined();
    });

    it('always creates gates and lifecycle groups', () => {
      const { groups } = buildData([]);
      expect(groups.map((g) => g.id)).toEqual(['gates', 'lifecycle']);
    });
  });

  describe('tooltipTemplate', () => {
    it('returns an empty string for background items', () => {
      const result = tooltipTemplate({ type: 'background' } as ProjectTimelineItem);
      expect(result).toBe('');
    });

    describe('for a phase item', () => {
      let result:HTMLElement;

      beforeEach(() => {
        result = tooltipTemplate({
          id: 'phase-1',
          group: 'lifecycle',
          type: 'range',
          start: new Date('2024-01-01'),
          end: new Date('2024-03-31'),
          content: 'Design',
          title: 'Design',
          className: '__hl_background_project_phase_definition_3',
          definitionId: 3,
        }) as HTMLElement;
      });

      it('returns an HTMLElement', () => {
        expect(result instanceof HTMLElement).toBe(true);
      });

      it('shows the date range in the meta row', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('Phase');
      });

      it('shows the phase name', () => {
        const name = result.querySelector('.op-timeline-tooltip--name');
        expect(name?.textContent).toBe('Design');
      });

      it('applies the highlight class to the type indicator', () => {
        expect(result.querySelector('.__hl_inline_project_phase_definition_3')).toBeTruthy();
      });
    });

    describe('for a gate item', () => {
      let result:HTMLElement;

      beforeEach(() => {
        result = tooltipTemplate({
          id: 'gate-start-2',
          group: 'gates',
          type: 'point',
          start: new Date('2024-04-01'),
          content: '',
          title: 'Build Start',
          className: 'op-timeline-gate __hl_background_project_phase_definition_5',
          definitionId: 5,
        }) as HTMLElement;
      });

      it('shows "Gate" as the type label', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('Gate');
      });

      it('shows only a single date (no range)', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).not.toContain('–');
      });

      it('shows the gate name', () => {
        const name = result.querySelector('.op-timeline-tooltip--name');
        expect(name?.textContent).toBe('Build Start');
      });

      it('applies the highlight class', () => {
        expect(result.querySelector('.__hl_inline_project_phase_definition_5')).toBeTruthy();
      });
    });
  });
});
