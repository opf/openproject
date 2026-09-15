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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ProjectTimelineItem, ProjectTimelineGraphComponent } from './project-timeline-graph.component';
import { ProjectTimelineItemBuilder } from './project-timeline-item.builder';
import { ProjectTimelineTooltipBuilder } from './project-timeline-tooltip.builder';
import type { TooltipView } from './project-timeline-tooltip.builder';
import { render } from 'lit-html';
import type { TemplateResult } from 'lit-html';
import '@openproject/primer-view-components/app/components/primer/anchored_position';

describe('ProjectTimelineGraphComponent', () => {
  const i18nStub = {
    t(key:string, options:Record<string, string> = {}):string {
      return {
        'js.grid.widgets.project_timeline.tooltip_type_phase': 'Phase',
        'js.grid.widgets.project_timeline.tooltip_type_gate': 'Gate',
        'js.grid.widgets.project_timeline.tooltip_type_milestone': 'Milestone',
        'js.grid.widgets.project_timeline.tooltip_type_sprint': 'Sprint',
        'js.grid.widgets.project_timeline.accessible_phase': `Phase ${options.name}: ${options.date}`,
        'js.grid.widgets.project_timeline.accessible_gate': `Phase gate ${options.name}: ${options.date}`,
        'js.grid.widgets.project_timeline.accessible_milestone': `Milestone ${options.name}: ${options.date}`,
        'js.grid.widgets.project_timeline.accessible_sprint': `Sprint ${options.name}: ${options.date}. Status: ${options.status}`,
        'js.grid.widgets.project_timeline.sprint_status.active': 'Active',
        'js.grid.widgets.project_timeline.sprint_status.completed': 'Completed',
        'js.grid.widgets.project_timeline.sprint_status.in_planning': 'In planning',
        'js.grid.widgets.project_timeline.accessible_date_range': `${options.start} to ${options.end}`,
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
    row: 0,
  };

  const sprint = {
    id: 20,
    name: 'Sprint 1',
    startDate: '2024-01-01',
    endDate: '2024-01-14',
    status: 'active',
    row: 0,
  };

  let fixture:ComponentFixture<ProjectTimelineGraphComponent>;
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  let component:ProjectTimelineGraphComponent;

  let buildData:(phases:unknown[], milestones:unknown[], sprints:unknown[]) => { items:ProjectTimelineItem[]; groups:{ id:string; content:string }[] };
  let tooltipTemplate:(item:ProjectTimelineItem) => HTMLElement|string;
  let popoverTemplate:(view:TooltipView) => TemplateResult;
  let buildAccessibleItems:(phases:unknown[], milestones:unknown[], sprints:unknown[]) => { id:string; text:string }[];

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

    const injector = fixture.debugElement.injector;
    const itemBuilder = injector.get(ProjectTimelineItemBuilder);
    const tooltipBuilder = injector.get(ProjectTimelineTooltipBuilder);

    buildData = itemBuilder.buildData.bind(itemBuilder);
    tooltipTemplate = tooltipBuilder.tooltipTemplate.bind(tooltipBuilder);
    popoverTemplate = tooltipBuilder.popoverTemplate.bind(tooltipBuilder);
    buildAccessibleItems = itemBuilder.buildAccessibleItems.bind(itemBuilder);
  });

  describe('buildData', () => {
    it('creates a range item for a phase with dates', () => {
      const { items } = buildData([phaseWithDates], [], []);
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
      const { items } = buildData([phaseWithoutDates], [], []);
      expect(items.find((i) => i.id === 'phase-3')).toBeUndefined();
    });

    it('creates start and finish gate items when configured', () => {
      const { items } = buildData([phaseWithGates], [], []);

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
      const { items } = buildData([phaseWithDates], [], []);
      expect(items.find((i) => i.id === 'gate-start-1')).toBeUndefined();
      expect(items.find((i) => i.id === 'gate-finish-1')).toBeUndefined();
    });

    describe('for a one-day phase', () => {
      let item:ProjectTimelineItem;

      beforeEach(() => {
        ({ items: [item] } = buildData([oneDayPhase], [], []));
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
      const { items } = buildData([], [milestone], []);
      const item = items.find((i) => i.id === 'milestone-10');

      expect(item).toBeDefined();
      expect(item!.type).toBe('point');
      expect(item!.group).toBe('milestones');
      expect(item!.title).toBe('Launch');
      expect(item!.className).toContain('op-timeline-milestone');
      expect(item!.className).toContain('__hl_background_type_7');
      expect(item!.itemType).toBe('milestone');
    });

    it('creates a sprint item', () => {
      const { items } = buildData([], [], [sprint]);
      const item = items.find((i) => i.id === 'sprint-20');

      expect(item).toBeDefined();
      expect(item!.type).toBe('range');
      expect(item!.group).toBe('sprints');
      expect(item!.start).toBe('2024-01-01');
      expect(item!.end).toBe('2024-01-14');
      expect(item!.content).toBe('Sprint 1');
      expect(item!.className).toContain('op-timeline-sprint');
      expect(item!.className).toContain('op-timeline-sprint--active');
      expect(item!.itemType).toBe('sprint');
    });

    it('does not add the active class for non-active sprints', () => {
      const { items } = buildData([], [], [{ ...sprint, status: 'in_planning' }]);
      const item = items.find((i) => i.id === 'sprint-20');
      expect(item!.className).not.toContain('op-timeline-sprint--active');
    });

    it('always creates gates, phases, milestones, and sprints groups', () => {
      const { groups } = buildData([], [], []);
      expect(groups.map((g) => g.id)).toEqual(['gates', 'phases', 'milestones', 'sprints']);
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
          start: '2024-01-01',
          end: '2024-03-31',
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

      it('shows "Phase" as the type label', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('Phase');
      });

      it('shows the date range', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('2024-01-01');
        expect(meta?.textContent).toContain('2024-03-31');
        expect(meta?.textContent).toContain('–');
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
          start: '2024-05-14',
          end: '2024-05-15',
          originalEnd: '2024-05-15',
          content: 'Kickoff',
          title: 'Kickoff',
          className: '__hl_background_project_phase_definition_9',
          definitionId: 9,
        }) as HTMLElement;
      });

      it('shows only a single date (no range)', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('2024-05-15');
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
          start: '2024-04-01',
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
        expect(meta?.textContent).toContain('2024-04-01');
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
          start: '2024-06-30',
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
        expect(meta?.textContent).toContain('2024-06-30');
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

    describe('for a sprint item', () => {
      let result:HTMLElement;

      beforeEach(() => {
        result = tooltipTemplate({
          id: 'sprint-20',
          group: 'sprints',
          type: 'range',
          start: '2024-01-01',
          end: '2024-01-14',
          content: 'Sprint 1',
          title: 'Sprint 1',
          className: 'op-timeline-sprint op-timeline-sprint--active',
          itemType: 'sprint',
        }) as HTMLElement;
      });

      it('shows "Sprint" as the type label', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('Sprint');
      });

      it('shows the date range', () => {
        const meta = result.querySelector('.op-timeline-tooltip--meta-row');
        expect(meta?.textContent).toContain('2024-01-01');
        expect(meta?.textContent).toContain('2024-01-14');
        expect(meta?.textContent).toContain('–');
      });

      it('shows the sprint name', () => {
        const name = result.querySelector('.op-timeline-tooltip--name');
        expect(name?.textContent).toBe('Sprint 1');
      });
    });

    describe('for a clustered gate item', () => {
      const octoberGate:ProjectTimelineItem = {
        id: 'gate-oct',
        group: 'gates',
        type: 'point',
        start: '2024-10-01',
        content: document.createElement('i'),
        title: 'October Gate',
        className: 'op-timeline-gate',
      };
      const novemberGate:ProjectTimelineItem = {
        id: 'gate-nov',
        group: 'gates',
        type: 'point',
        start: '2024-11-01',
        content: document.createElement('i'),
        title: 'November Gate',
        className: 'op-timeline-gate',
      };

      const makeCluster = (items:ProjectTimelineItem[]):HTMLElement => tooltipTemplate({
        id: 'cluster-1',
        group: 'gates',
        type: 'point',
        start: '2024-10-01',
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
        const formattedDates:string[] = [];
        vi.spyOn(timezoneStub, 'formattedDate').mockImplementation((d:unknown) => {
          formattedDates.push(d as string);
          return String(d);
        });

        // Items intentionally in reverse order (November before October)
        makeCluster([novemberGate, octoberGate]);

        expect(formattedDates.length).toBe(2);
        expect(formattedDates[0] < formattedDates[1]).toBe(true);
      });
    });
  });

  describe('popoverTemplate', () => {
    const renderView = (view:Partial<TooltipView>) => {
      const host = document.createElement('div');
      render(popoverTemplate({ anchor: null, content: null, caret: null, ...view }), host);
      return {
        popover: host.querySelector<HTMLElement & { anchorElement:Element | null }>('anchored-position')!,
        message: host.querySelector<HTMLElement>('.Popover-message')!,
      };
    };

    it('renders a manual popover anchored above the given element', () => {
      const anchor = document.createElement('span');
      const { popover } = renderView({ anchor, content: 'Launch' });

      expect(popover.getAttribute('popover')).toBe('manual');
      expect(popover.getAttribute('side')).toBe('outside-top');
      expect(popover.anchorElement).toBe(anchor);
      expect(popover.textContent).toContain('Launch');
    });

    it('renders no caret side until the placement is known', () => {
      const { message } = renderView({ content: 'Launch' });

      expect(Array.from(message.classList)).toEqual(['Popover-message']);
      expect(message.style.getPropertyValue('--op-timeline-tooltip-caret-offset')).toBe('');
    });

    it('turns the caret to face the anchor at the given offset', () => {
      const { message } = renderView({ content: 'Launch', caret: { side: 'left', offset: 30 } });

      expect(message.classList.contains('Popover-message--left')).toBe(true);
      expect(message.classList.contains('Popover-message--bottom')).toBe(false);
      expect(message.style.getPropertyValue('--op-timeline-tooltip-caret-offset')).toBe('30px');
    });

    it('drops the sideways caret when the popover moves back above the anchor', () => {
      const host = document.createElement('div');
      render(popoverTemplate({ anchor: null, content: 'Launch', caret: { side: 'left', offset: 30 } }), host);
      render(popoverTemplate({ anchor: null, content: 'Launch', caret: { side: 'bottom', offset: 50 } }), host);

      const message = host.querySelector<HTMLElement>('.Popover-message')!;
      expect(message.classList.contains('Popover-message--left')).toBe(false);
      expect(message.classList.contains('Popover-message--bottom')).toBe(true);
    });
  });

  describe('buildAccessibleItems', () => {
    it('creates screen reader text for phases and gates', () => {
      expect(buildAccessibleItems([phaseWithGates], [], [])).toEqual([
        { id: 'phase-2', text: 'Phase Build: 2024-04-01 to 2024-06-30' },
        { id: 'gate-start-2', text: 'Phase gate Build Start: 2024-04-01' },
        { id: 'gate-finish-2', text: 'Phase gate Build End: 2024-06-30' },
      ]);
    });

    it('uses a single date for one-day phases', () => {
      expect(buildAccessibleItems([oneDayPhase], [], [])).toEqual([
        { id: 'phase-4', text: 'Phase Kickoff: 2024-05-15' },
      ]);
    });

    it('skips phases without dates', () => {
      expect(buildAccessibleItems([phaseWithoutDates], [], [])).toEqual([]);
    });

    it('creates screen reader text for milestones', () => {
      expect(buildAccessibleItems([], [milestone], [])).toEqual([
        { id: 'milestone-10', text: 'Milestone Launch: 2024-06-30' },
      ]);
    });

    it('creates screen reader text for sprints', () => {
      expect(buildAccessibleItems([], [], [sprint])).toEqual([
        { id: 'sprint-20', text: 'Sprint Sprint 1: 2024-01-01 to 2024-01-14. Status: Active' },
      ]);
    });

    it('orders all item types chronologically', () => {
      expect(buildAccessibleItems([phaseWithGates], [milestone], [sprint]).map(({ id }) => id)).toEqual([
        'sprint-20',
        'phase-2',
        'gate-start-2',
        'gate-finish-2',
        'milestone-10',
      ]);
    });
  });

  describe('template', () => {
    it('does not render an empty screen reader list', () => {
      const element = fixture.nativeElement as HTMLElement;

      expect(element.querySelector('ul.sr-only')).toBeNull();
    });

    it('renders screen reader text and hides the visual graph from assistive technology', () => {
      fixture.componentRef.setInput('phasesData', JSON.stringify([phaseWithGates]));
      fixture.detectChanges();

      const element = fixture.nativeElement as HTMLElement;
      expect(element.querySelector('.op-project-timeline-graph')?.getAttribute('aria-hidden')).toBe('true');
      expect(element.querySelector('ul.sr-only')?.textContent).toContain('Phase Build: 2024-04-01 to 2024-06-30');
      expect(element.querySelector('ul.sr-only')?.textContent).toContain('Phase gate Build Start: 2024-04-01');
      expect(element.querySelector('ul.sr-only')?.textContent).toContain('Phase gate Build End: 2024-06-30');
    });

    it('renders milestone and sprint screen reader text', () => {
      fixture.componentRef.setInput('milestonesData', JSON.stringify([milestone]));
      fixture.componentRef.setInput('sprintsData', JSON.stringify([sprint]));
      fixture.detectChanges();

      const text = (fixture.nativeElement as HTMLElement).querySelector('ul.sr-only')?.textContent;
      expect(text).toContain('Milestone Launch: 2024-06-30');
      expect(text).toContain('Sprint Sprint 1: 2024-01-01 to 2024-01-14. Status: Active');
    });

    it('hides the loading skeleton once the initial draw completes', async () => {
      const element = fixture.nativeElement as HTMLElement;

      await vi.waitUntil(() => {
        fixture.detectChanges();
        return element.querySelector('.op-project-timeline-graph--wrapper_loading') === null;
      });

      expect(element.querySelector('.op-project-timeline-graph--wrapper_loading')).toBeNull();
    });
  });

  describe('hover tooltip', () => {
    const hover = (type:'mouseover' | 'mouseout', target:Element) => {
      target.dispatchEvent(new MouseEvent(type, { bubbles: true, clientX: 10, clientY: 10 }));
    };

    let element:HTMLElement;

    // Only the hover delay is faked; the caret waits for a real animation frame.
    const fakeHoverDelay = () => vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });

    const popover = () => element.querySelector<HTMLElement>('.op-project-timeline-graph--tooltip')!;
    const message = () => popover().querySelector<HTMLElement>('.Popover-message')!;
    const isOpen = () => popover().matches(':popover-open');

    const renderItems = async (selector:string, inputs:Record<string, unknown[]>) => {
      for (const [name, value] of Object.entries(inputs)) {
        fixture.componentRef.setInput(name, JSON.stringify(value));
      }
      fixture.detectChanges();
      element = fixture.nativeElement as HTMLElement;

      await vi.waitUntil(() => {
        fixture.detectChanges();
        return element.querySelector(selector) !== null;
      });
      return element.querySelector<HTMLElement>(selector)!;
    };

    const caretOffsetValue = () => message().style.getPropertyValue('--op-timeline-tooltip-caret-offset');

    const openTooltip = async (item:Element) => {
      fakeHoverDelay();
      hover('mouseover', item);
      vi.advanceTimersByTime(500);
      vi.useRealTimers();
      await vi.waitUntil(() => caretOffsetValue() !== '');
    };

    const caretOffset = () => parseFloat(caretOffsetValue());
    const expectedCaretOffset = (anchor:DOMRect) => {
      const box = popover().getBoundingClientRect();
      const center = anchor.left + anchor.width / 2 - box.left;
      return Math.min(Math.max(center, 12), box.width - 12);
    };

    afterEach(() => {
      vi.useRealTimers();
    });

    describe('for a milestone', () => {
      let milestoneItem:HTMLElement;

      beforeEach(async () => {
        milestoneItem = await renderItems('.vis-item.vis-point', { milestonesData: [milestone] });
      });

      it('does not use the vis-timeline tooltip that the grid cell would clip', () => {
        hover('mouseover', milestoneItem);
        expect(element.querySelector('.vis-tooltip')).toBeNull();
      });

      it('keeps the popover inside the aria-hidden container', () => {
        expect(popover().closest('[aria-hidden="true"]')).not.toBeNull();
      });

      it('opens the tooltip in the top layer after the hover delay', () => {
        fakeHoverDelay();
        hover('mouseover', milestoneItem);
        expect(isOpen()).toBe(false);

        vi.advanceTimersByTime(500);
        expect(isOpen()).toBe(true);
        expect(popover().textContent).toContain('Launch');
        expect(popover().textContent).toContain('Milestone');
      });

      it('closes the tooltip when the pointer leaves the item', () => {
        fakeHoverDelay();
        hover('mouseover', milestoneItem);
        vi.advanceTimersByTime(500);
        expect(isOpen()).toBe(true);

        hover('mouseout', milestoneItem);
        expect(isOpen()).toBe(false);
      });

      it('does not open when the pointer leaves before the delay', () => {
        fakeHoverDelay();
        hover('mouseover', milestoneItem);
        hover('mouseout', milestoneItem);

        vi.advanceTimersByTime(1000);
        expect(isOpen()).toBe(false);
      });

      it('reuses one popover element across hovers', () => {
        const before = popover();
        fakeHoverDelay();
        hover('mouseover', milestoneItem);
        vi.advanceTimersByTime(500);
        hover('mouseout', milestoneItem);
        expect(popover()).toBe(before);
      });

      it('points the caret at the diamond from the side facing it', async () => {
        await openTooltip(milestoneItem);

        const diamond = milestoneItem.querySelector('.vis-dot')!.getBoundingClientRect();
        const box = popover().getBoundingClientRect();
        const popoverIsAbove = box.bottom <= diamond.top;
        const popoverIsBelow = box.top >= diamond.bottom;

        expect(caretOffset()).toBeCloseTo(expectedCaretOffset(diamond), 0);
        expect(popoverIsAbove || popoverIsBelow).toBe(true);
        expect(message().classList.contains('Popover-message--bottom')).toBe(popoverIsAbove);
      });

      it('closes the tooltip when the page scrolls', async () => {
        await openTooltip(milestoneItem);
        expect(isOpen()).toBe(true);

        document.dispatchEvent(new Event('scroll'));
        expect(isOpen()).toBe(false);
      });

      it('closes the tooltip when the window is resized', async () => {
        await openTooltip(milestoneItem);
        expect(isOpen()).toBe(true);

        window.dispatchEvent(new Event('resize'));
        expect(isOpen()).toBe(false);
      });

      it('closes the tooltip when the data is replaced', () => {
        fakeHoverDelay();
        hover('mouseover', milestoneItem);
        vi.advanceTimersByTime(500);
        expect(isOpen()).toBe(true);

        fixture.componentRef.setInput('milestonesData', JSON.stringify([{ ...milestone, subject: 'Relaunch' }]));
        fixture.detectChanges();
        expect(isOpen()).toBe(false);
      });

      it('drops a pending tooltip when the data is replaced', () => {
        fakeHoverDelay();
        hover('mouseover', milestoneItem);

        fixture.componentRef.setInput('milestonesData', JSON.stringify([{ ...milestone, subject: 'Relaunch' }]));
        fixture.detectChanges();
        vi.advanceTimersByTime(1000);
        expect(isOpen()).toBe(false);
      });
    });

    it('keeps a long milestone name inside the viewport', async () => {
      const longName = 'really long milestone '.repeat(12).trim();
      const item = await renderItems('.vis-item.vis-point', { milestonesData: [{ ...milestone, subject: longName }] });
      await openTooltip(item);

      const box = popover().getBoundingClientRect();
      expect(box.left).toBeGreaterThanOrEqual(0);
      expect(box.right).toBeLessThanOrEqual(window.innerWidth);
      expect(popover().textContent).toContain(longName);
    });

    it('anchors a phase bar on the bar itself', async () => {
      const bar = await renderItems('.vis-item.vis-range', { phasesData: [phaseWithDates] });
      await openTooltip(bar);

      expect(caretOffset()).toBeCloseTo(expectedCaretOffset(bar.getBoundingClientRect()), 0);
      expect(popover().textContent).toContain('Design');
    });

    it('anchors a gate on its visible icon rather than the hidden dot', async () => {
      const gate = await renderItems('.vis-item.vis-point.op-timeline-gate', { phasesData: [phaseWithGates] });
      await openTooltip(gate);

      const icon = gate.getBoundingClientRect();
      expect(icon.width).toBeGreaterThan(0);
      expect(caretOffset()).toBeCloseTo(expectedCaretOffset(icon), 0);
      expect(popover().textContent).toContain('Build Start');
    });

    it('shows every gate of a cluster', async () => {
      const secondPhase = { ...phaseWithGates, id: 3, name: 'Test', startGateName: 'Test Start', finishGate: false };
      const cluster = await renderItems('.vis-item.vis-cluster', { phasesData: [phaseWithGates, secondPhase] });
      await openTooltip(cluster);

      expect(popover().textContent).toContain('Build Start');
      expect(popover().textContent).toContain('Test Start');
    });
  });
});
