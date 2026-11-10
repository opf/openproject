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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { CommonModule } from '@angular/common';
import { ScrollingModule } from '@angular/cdk/scrolling';
import { TestBed } from '@angular/core/testing';
import { BehaviorSubject, ReplaySubject } from 'rxjs';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { ColorsService } from 'core-app/shared/components/colors/colors.service';
import { PrimerCounterComponent } from 'core-app/shared/components/primer/counter.component';
import { ContentLoaderModule } from '@ngneat/content-loader';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { OpContentLoaderComponent } from 'core-app/shared/components/op-content-loader/op-content-loader.component';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IanCenterService } from './center/state/ian-center.service';
import { IanBellService } from './bell/state/ian-bell.service';
import { InAppNotificationCenterComponent } from './center/in-app-notification-center.component';
import { InAppNotificationEntryComponent } from './entry/in-app-notification-entry.component';
import { InAppNotificationStatusComponent } from './entry/status/in-app-notification-status.component';
import { InAppNotificationActorsLineComponent } from './entry/actors-line/in-app-notification-actors-line.component';
import { InAppNotificationDateAlertComponent } from './entry/date-alert/in-app-notification-date-alert.component';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { InAppNotificationReminderAlertComponent } from './entry/reminder-alert/in-app-notification-reminder-alert.component';

describe('Notification template contracts', () => {
  const link = { href: '/api/v3/work_packages/42', title: 'Work package' };
  const notification:INotification = {
    id: 'notification-7', subject: 'Work package', createdAt: '2026-10-29T10:00:00Z', updatedAt: '2026-10-29T10:00:00Z',
    reason: 'mentioned', readIAN: false, readEmail: null, expanded: false,
    _links: { self: link, actor: link, project: { href: '/api/v3/projects/7', title: 'Project' }, resource: link, activity: link },
    _embedded: { details: [] },
  };

  function setup() {
    const count = new ReplaySubject<number>(1);
    const loading = new ReplaySubject<boolean>(1);
    const hasNotifications = new ReplaySubject<boolean>(1);
    const notifications = new ReplaySubject<INotification[][]>(1);
    const selected = new BehaviorSubject<string|null>(null);
    const workPackage = new ReplaySubject<WorkPackageResource>(1);
    const markAsRead = vi.fn();
    const openSplitScreen = vi.fn();
    const cached = { displayId: 'DEMO-42' };
    TestBed.configureTestingModule({
      imports: [CommonModule, ScrollingModule, PrimerCounterComponent, ContentLoaderModule, OpTooltipDirective],
      declarations: [OpContentLoaderComponent, InAppNotificationCenterComponent, InAppNotificationEntryComponent, InAppNotificationStatusComponent,
        InAppNotificationActorsLineComponent, InAppNotificationDateAlertComponent, InAppNotificationReminderAlertComponent],
      providers: [
        provideHttpClient(), provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key, locale: 'en' } },
        { provide: TimezoneService, useValue: {} },
        { provide: PathHelperService, useValue: {
          myNotificationsSettingsPath: () => '/my/notifications', projectPath: (id:string) => `/projects/${id}`,
          workPackagePath: (id:string) => `/work_packages/${id}`,
        } },
        { provide: DeviceService, useValue: { isMobile: false } },
        { provide: UrlParamsService, useValue: { get: () => null } },
        { provide: ColorsService, useValue: { colorMode: () => 'light' } },
        { provide: ApiV3Service, useValue: { work_packages: {
          id: () => ({ requireAndStream: () => workPackage }), cache: { current: () => cached },
        } } },
        { provide: IanBellService, useValue: { unread$: count } },
        { provide: IanCenterService, useValue: {
          loading$: loading, hasNotifications$: hasNotifications, notifications$: notifications,
          selectedWorkPackage$: selected, hasMoreThanPageSize$: new BehaviorSubject(false), notLoaded$: new BehaviorSubject(0),
          query: { selectLoading: () => loading }, setFacet: vi.fn(), setFilters: vi.fn(), markAsRead, openSplitScreen,
        } },
      ],
    });
    for (const component of [InAppNotificationActorsLineComponent, InAppNotificationDateAlertComponent,
      InAppNotificationReminderAlertComponent]) {
      TestBed.overrideComponent(component, { set: { template: '' } });
    }
    return { count, loading, hasNotifications, notifications, selected, workPackage, markAsRead, openSplitScreen };
  }

  it('keeps unresolved and empty counts distinct while loading and filtering', () => {
    const { count, loading, hasNotifications, markAsRead } = setup();
    const fixture = TestBed.createComponent(InAppNotificationCenterComponent);
    const host = fixture.nativeElement as HTMLElement;

    fixture.detectChanges();

    expect(host.querySelector('[data-test-selector="op-ian-center--loading-indicator"]')).toBeInTheDocument();

    loading.next(false);
    hasNotifications.next(false);
    fixture.detectChanges();

    expect(host).toHaveTextContent('js.notifications.center.empty_state.no_notification');
    expect(host).not.toHaveTextContent('js.notifications.center.no_results.at_all');
    expect(host).not.toHaveTextContent('js.notifications.center.no_results.with_current_filter');

    count.next(3);
    fixture.detectChanges();

    expect(host).toHaveTextContent('js.notifications.center.empty_state.no_notification_for_filter');
    expect(host).toHaveTextContent('js.notifications.center.no_results.with_current_filter');

    count.next(0);
    fixture.detectChanges();

    expect(host).toHaveTextContent('js.notifications.center.no_results.at_all');
    expect(markAsRead).not.toHaveBeenCalled();
  });

  it('preserves first-group selection by numeric and display identifiers without read side effects', () => {
    const { notifications, selected, markAsRead } = setup();
    const fixture = TestBed.createComponent(InAppNotificationCenterComponent);
    const values:boolean[] = [];
    const subscription = fixture.componentInstance.firstNotificationIsSelected$.subscribe((value) => values.push(value));

    notifications.next([]);
    selected.next('42');
    notifications.next([[notification]]);
    selected.next('DEMO-42');
    selected.next('43');

    expect(values).toEqual([false, false, true, true, false]);
    expect(markAsRead).not.toHaveBeenCalled();
    subscription.unsubscribe();
  });

  function renderEntry() {
    const state = setup();
    const fixture = TestBed.createComponent(InAppNotificationEntryComponent);
    fixture.componentRef.setInput('notification', notification);
    fixture.componentRef.setInput('aggregatedNotifications', [notification, { ...notification, id: 'notification-8' }]);
    fixture.detectChanges();
    const view = within(fixture.nativeElement as HTMLElement);
    return { ...state, fixture, view };
  }

  function loadWorkPackage({ fixture, workPackage }:ReturnType<typeof renderEntry>):void {
    const factory = TestBed.inject(HalResourceService);
    factory.registerResource('WorkPackage', { cls: WorkPackageResource });
    workPackage.next(factory.createHalResourceOfType<WorkPackageResource>('WorkPackage', {
      id: '42', displayId: 'DEMO-42', subject: 'Work package',
      _links: { self: link, status: { href: '/api/v3/statuses/1', title: 'Open' }, type: { href: '/api/v3/types/2', title: 'Task' } },
    }, true));
    fixture.detectChanges();
  }

  function entry() {
    const state = renderEntry();
    loadWorkPackage(state);
    return state;
  }

  const markAsReadName = 'js.notifications.center.mark_as_read';

  it.each([
    { activation: 'ctrl-click', fire: (button:HTMLElement) => fireEvent.click(button, { ctrlKey: true }), prevented: false },
    { activation: 'Enter', fire: (button:HTMLElement) => fireEvent.keyDown(button, { key: 'Enter' }), prevented: true },
    { activation: 'Space', fire: (button:HTMLElement) => fireEvent.keyDown(button, { key: ' ' }), prevented: true },
  ])('marks only the aggregated records on $activation without opening details', ({ fire, prevented }) => {
    const { fixture, view, markAsRead, openSplitScreen } = entry();
    const clicked = vi.spyOn(fixture.componentInstance, 'onClick');

    const notPrevented = fire(view.getByRole('button', { name: markAsReadName }));

    expect(markAsRead).toHaveBeenCalledExactlyOnceWith(['notification-7', 'notification-8']);
    expect(clicked).not.toHaveBeenCalled();
    expect(openSplitScreen).not.toHaveBeenCalled();
    expect(notPrevented).toBe(!prevented);
  });

  it.each(['ctrlKey', 'shiftKey', 'metaKey'])('preserves the existing %s keyboard binding filter', (modifier) => {
    const { fixture, view, markAsRead, openSplitScreen } = entry();
    const clicked = vi.spyOn(fixture.componentInstance, 'onClick');

    const notPrevented = fireEvent.keyDown(view.getByRole('button', { name: markAsReadName }), { key: 'Enter', [modifier]: true });

    expect(markAsRead).not.toHaveBeenCalled();
    expect(clicked).not.toHaveBeenCalled();
    expect(openSplitScreen).not.toHaveBeenCalled();
    expect(notPrevented).toBe(true);
  });

  it.each(['Enter', ' '])('opens the selected work-package details on %s without marking records read', async (key) => {
    const { fixture, openSplitScreen, markAsRead } = entry();
    const row = (fixture.nativeElement as HTMLElement).querySelector<HTMLElement>('.op-ian-item--row')!;

    const notPrevented = fireEvent.keyDown(row, { key });

    await waitFor(() => expect(openSplitScreen).toHaveBeenCalledExactlyOnceWith('DEMO-42', 'activity'));
    expect(notPrevented).toBe(false);
    expect(markAsRead).not.toHaveBeenCalled();
  });

  it('shows mark-as-read actions for a loaded unread record and hides them once read', () => {
    const state = renderEntry();
    const { fixture, view, markAsRead } = state;

    expect(view.queryByRole('button', { name: markAsReadName })).not.toBeInTheDocument();

    loadWorkPackage(state);

    expect(view.getByRole('button', { name: markAsReadName })).toBeInTheDocument();

    fixture.componentRef.setInput('notification', { ...notification, readIAN: true });
    fixture.detectChanges();

    expect(view.queryByRole('button', { name: markAsReadName })).not.toBeInTheDocument();
    expect(markAsRead).not.toHaveBeenCalled();
  });

  it.each(['DEMO-42', 'Project'])('keeps the native %s link from selecting the notification', (name) => {
    const { fixture, view, markAsRead } = entry();
    const clicked = vi.spyOn(fixture.componentInstance, 'onClick');
    const anchor = view.getByRole('link', { name });
    let preventedByHandler = true;
    anchor.addEventListener('click', (activation) => {
      preventedByHandler = activation.defaultPrevented;
      activation.preventDefault();
    }, { once: true });

    fireEvent.click(anchor, { ctrlKey: true });

    expect(preventedByHandler).toBe(false);
    expect(clicked).not.toHaveBeenCalled();
    expect(markAsRead).not.toHaveBeenCalled();
  });
});
