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
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ProjectTimelineItem, ProjectTimelineGraphComponent } from './project-timeline-graph.component';

describe('ProjectTimelineGraphComponent', () => {
  const i18nStub = {
    t(key:string):string {
      return {
        'js.grid.widgets.project_timeline.tooltip_type_phase': 'Phase',
        'js.grid.widgets.project_timeline.tooltip_type_gate': 'Gate',
        'js.grid.widgets.project_timeline.tooltip_type_milestone': 'Milestone',
      }[key] ?? key;
    },
  };

  const timezoneStub = {
    formattedDate(date:string):string { return date; },
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

  const oneDayPhase = {
    id: 4,
    definitionId: 9,
    name: 'Kickoff',
    startDate: '2024-05-15',
    endDate: '2024-05-15',
    startGate: false,
    startGateName: null,
    finishGate: false,
    finishGateName: null,
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

  const milestone = {
    id: 10,
    subject: 'Launch',
    date: '2024-06-30',
    typeId: 7,
  };

  let fixture:ComponentFixture<ProjectTimelineGraphComponent>;
  let component:ProjectTimelineGraphComponent;

  let buildData:(phases:unknown[], milestones:unknown[]) => { items:ProjectTimelineItem[]; groups:{ id:string; content:string }[] };
  let tooltipTemplate:(item:ProjectTimelineItem) => HTMLElement|string;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ProjectTimelineGraphComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
        { provide: TimezoneService, useValue: timezoneStub },
        { provide: PathHelperService, useValue: { workPackagePath: (id:string) => `/work_packages/${id}` } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ProjectTimelineGraphComponent);
    component = fixture.componentInstance;

    // Set required inputs before detectChanges triggers ngAfterViewInit
    fixture.componentRef.setInput('phasesData', '[]');
    fixture.componentRef.setInput('milestonesData', '[]');
    fixture.detectChanges();

    // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
    buildData = (component as any).buildData.bind(component);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
    tooltipTemplate = (component as any).tooltipTemplate.bind(component);
  });

  describe('buildData', () => {
    it('creates a range item for a phase with dates', () => {
      const { items } = buildData([phaseWithDates], []);
      const item = items.find((i) => i.id === 'phase-1');

      expect(item).toBeDefined();
      expect(item!.type).toBe('range');
      expect(item!.group).toBe('phases');
      expect(item!.content).toBe('Design');
      expect(item!.className).toContain('__hl_background_project_phase_definition_3');
      expect(item!.itemType).toBe('phase');
      expect(item!.definitionId).toBe(3);
    });

    it('skips a phase without dates', () => {
      const { items } = buildData([phaseWithoutDates], []);
      expect(items.find((i) => i.id === 'phase-3')).toBeUndefined();
    });

    it('creates start and finish gate items when configured', () => {
      const { items } = buildData([phaseWithGates], []);

      const startGate = items.find((i) => i.id === 'gate-start-2');
      expect(startGate).toBeDefined();
      expect(startGate!.type).toBe('point');
      expect(startGate!.group).toBe('gates');
      expect(startGate!.title).toBe('Build Start');
      expect(startGate!.className).toContain('op-timeline-gate');
      expect(startGate!.itemType).toBe('gate');
      expect(startGate!.content instanceof HTMLElement).toBe(true);
      expect((startGate!.content as HTMLElement).querySelector('.__hl_inline_project_phase_definition_5')).toBeTruthy();

      const finishGate = items.find((i) => i.id === 'gate-finish-2');
      expect(finishGate).toBeDefined();
      expect(finishGate!.title).toBe('Build End');
    });

    it('does not create gate items when gates are disabled', () => {
      const { items } = buildData([phaseWithDates], []);
      expect(items.find((i) => i.id === 'gate-start-1')).toBeUndefined();
      expect(items.find((i) => i.id === 'gate-finish-1')).toBeUndefined();
    });

    describe('for a one-day phase', () => {
      let item:ProjectTimelineItem;

      beforeEach(() => {
        ({ items: [item] } = buildData([oneDayPhase], []));
      });

      it('creates a range item', () => {
        expect(item).toBeDefined();
        expect(item.type).toBe('range');
      });

      it('sets start to previous day local noon', () => {
        expect(item.start instanceof Date).toBe(true);
        const start = item.start as Date;
        expect(start.getHours()).toBe(12);
        expect(start.getDate()).toBe(14); // day before May 15
      });

      it('sets end to same day local noon', () => {
        expect(item.end instanceof Date).toBe(true);
        const end = item.end as Date;
        expect(end.getHours()).toBe(12);
        expect(end.getDate()).toBe(15);
      });

      it('stores originalEnd as the original date string', () => {
        expect(item.originalEnd).toBe('2024-05-15');
      });
    });

    it('creates a milestone item', () => {
      const { items } = buildData([], [milestone]);
      const item = items.find((i) => i.id === 'milestone-10');

      expect(item).toBeDefined();
      expect(item!.type).toBe('point');
      expect(item!.group).toBe('milestones');
      expect(item!.title).toBe('Launch');
      expect(item!.className).toContain('op-timeline-milestone');
      expect(item!.className).toContain('__hl_background_type_7');
      expect(item!.itemType).toBe('milestone');
    });

    it('always creates gates, lifecycle, and milestones groups', () => {
      const { groups } = buildData([], []);
      expect(groups.map((g) => g.id)).toEqual(['gates', 'phases', 'milestones']);
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
          itemType: 'phase',
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

    describe('for a one-day phase item', () => {
      let result:HTMLElement;

      beforeEach(() => {
        result = tooltipTemplate({
          id: 'phase-4',
          group: 'lifecycle',
          type: 'range',
          start: new Date('2024-05-14T12:00:00'),
          end: new Date('2024-05-15T12:00:00'),
          originalEnd: '2024-05-15',
          content: 'Kickoff',
          title: 'Kickoff',
          className: '__hl_background_project_phase_definition_9',
          definitionId: 9,
        }) as HTMLElement;
      });

      it('shows only a single date (no range)', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).not.toContain('–');
      });

      it('shows the phase name', () => {
        const name = result.querySelector('.op-timeline-tooltip--name');
        expect(name?.textContent).toBe('Kickoff');
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
          content: document.createElement('i'),
          title: 'Build Start',
          className: 'op-timeline-gate __hl_background_project_phase_definition_5',
          itemType: 'gate',
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

    describe('for a milestone item', () => {
      let result:HTMLElement;

      beforeEach(() => {
        result = tooltipTemplate({
          id: 'milestone-10',
          group: 'milestones',
          type: 'point',
          start: new Date('2024-06-30'),
          content: '',
          title: 'Launch',
          className: 'op-timeline-milestone __hl_background_type_7',
          itemType: 'milestone',
          typeId: 7,
        }) as HTMLElement;
      });

      it('shows "Milestone" as the type label', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('Milestone');
      });

      it('shows only a single date (no range)', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).not.toContain('–');
      });

      it('shows the milestone name', () => {
        const name = result.querySelector('.op-timeline-tooltip--name');
        expect(name?.textContent).toBe('Launch');
      });

      it('applies the type highlight class to the icon', () => {
        expect(result.querySelector('.__hl_inline_type_7')).toBeTruthy();
      });
    });

    describe('for a clustered gate item', () => {
      const octoberGate:ProjectTimelineItem = {
        id: 'gate-oct',
        group: 'gates',
        type: 'point',
        start: new Date('2024-10-01'),
        content: document.createElement('i'),
        title: 'October Gate',
        className: 'op-timeline-gate',
      };
      const novemberGate:ProjectTimelineItem = {
        id: 'gate-nov',
        group: 'gates',
        type: 'point',
        start: new Date('2024-11-01'),
        content: document.createElement('i'),
        title: 'November Gate',
        className: 'op-timeline-gate',
      };

      const makeCluster = (items:ProjectTimelineItem[]):HTMLElement => tooltipTemplate({
        id: 'cluster-1',
        group: 'gates',
        type: 'point',
        start: new Date('2024-10-01'),
        content: document.createElement('i'),
        title: '',
        className: 'op-timeline-gate',
        isCluster: true,
        items,
      }) as HTMLElement;

      it('shows "Gate" as the type label', () => {
        const meta = makeCluster([octoberGate, novemberGate]).querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('Gate');
      });

      it('lists all gate names', () => {
        const name = makeCluster([octoberGate, novemberGate]).querySelector('.op-timeline-tooltip--name');
        expect(name?.textContent).toBe('October Gate, November Gate');
      });

      it('sorts dates chronologically even when items arrive in reverse order', () => {
        const formattedDates:Date[] = [];
        vi.spyOn(timezoneStub, 'formattedDate').mockImplementation((d:unknown) => {
          formattedDates.push(d as Date);
          return String(d);
        });

        // Items intentionally in reverse order (November before October)
        makeCluster([novemberGate, octoberGate]);

        expect(formattedDates.length).toBe(2);
        expect(formattedDates[0].getTime()).toBeLessThan(formattedDates[1].getTime());
      });
    });
  });
});
