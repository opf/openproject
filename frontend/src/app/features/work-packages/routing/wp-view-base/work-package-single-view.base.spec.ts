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

import { Component, OnInit } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import type { Mock } from 'vitest';
import { screen } from '@testing-library/dom';
import { BehaviorSubject, Subject } from 'rxjs';
import { WorkPackageSingleViewBase } from 'core-app/features/work-packages/routing/wp-view-base/work-package-single-view.base';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';

@Component({
  selector: 'op-test-single-view',
  template: `
    @if (workPackage) {
      <p data-testid="work-package">{{ workPackage.subject }}</p>
    }
  `,
})
class TestSingleViewComponent extends WorkPackageSingleViewBase implements OnInit {
  initCalls = 0;

  ngOnInit():void {
    this.observeWorkPackage();
  }

  protected init():void {
    this.initCalls += 1;
  }
}

describe('WorkPackageSingleViewBase', () => {
  let fixture:ComponentFixture<TestSingleViewComponent>;
  let semanticSlot:Subject<WorkPackageResource>;
  let numericSlot:Subject<WorkPackageResource>;
  let ensureLoaded:Mock<SchemaCacheService['ensureLoaded']>;
  let handleRawError:Mock<WorkPackageNotificationService['handleRawError']>;

  const workPackage = (id:string, subject:string) => ({
    id,
    subject,
    subjectWithType: () => subject,
  } satisfies Pick<WorkPackageResource, 'id' | 'subject' | 'subjectWithType'>) as unknown as WorkPackageResource;

  const deferred = () => {
    let resolve!:() => void;
    const promise = new Promise<SchemaResource>((res) => {
      resolve = () => res({} as SchemaResource);
    });
    return { promise, resolve };
  };

  const settled = () => new Promise((resolve) => { setTimeout(resolve); });

  const render = async (workPackageId = '1') => {
    fixture = TestBed.createComponent(TestSingleViewComponent);
    fixture.componentInstance.workPackageId = workPackageId;
    await fixture.whenStable();
  };

  beforeEach(() => {
    semanticSlot = new Subject();
    numericSlot = new Subject();
    ensureLoaded = vi.fn<SchemaCacheService['ensureLoaded']>();
    handleRawError = vi.fn<WorkPackageNotificationService['handleRawError']>();

    const apiV3Service = {
      work_packages: {
        id: () => ({ requireAndStream: () => semanticSlot }),
        cache: {
          state: () => ({
            values$: () => numericSlot,
            hasValue: () => numericSlot instanceof BehaviorSubject,
          }),
        },
      },
    };

    TestBed.configureTestingModule({
      imports: [TestSingleViewComponent],
      providers: [
        { provide: SchemaCacheService, useValue: { ensureLoaded } },
        { provide: ApiV3Service, useValue: apiV3Service },
        { provide: OpTitleService, useValue: { setFirstPart: () => undefined } },
        { provide: States, useValue: {} },
        { provide: I18nService, useValue: { t: () => '' } },
        { provide: KeepTabService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        { provide: HalResourceEditingService, useValue: {} },
        { provide: WorkPackageViewFocusService, useValue: {} },
        { provide: WorkPackageNotificationService, useValue: { handleRawError } },
        { provide: AuthorisationService, useValue: {} },
        { provide: AttachmentsResourceService, useValue: {} },
        { provide: FileLinksResourceService, useValue: {} },
        { provide: ProjectsResourceService, useValue: {} },
        { provide: StoragesResourceService, useValue: {} },
        { provide: ToastService, useValue: {} },
        { provide: HookService, useValue: {} },
        { provide: ActionsService, useValue: {} },
        { provide: WpSingleViewService, useValue: {} },
      ],
    });
  });

  it('does not render the work package before its schema is loaded', async () => {
    const schema = deferred();
    ensureLoaded.mockReturnValue(schema.promise);
    await render();

    semanticSlot.next(workPackage('1', 'Landing page'));
    await settled();
    await fixture.whenStable();

    expect(screen.queryByTestId('work-package')).toBeNull();
    expect(fixture.componentInstance.initCalls).toBe(0);

    schema.resolve();
    await settled();
    await fixture.whenStable();

    expect(screen.getByTestId('work-package').textContent).toBe('Landing page');
    expect(fixture.componentInstance.initCalls).toBe(1);
  });

  it('applies only the latest emission while a schema load is pending', async () => {
    const first = deferred();
    const second = deferred();
    ensureLoaded.mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise);
    await render();

    semanticSlot.next(workPackage('1', 'Old subject'));
    semanticSlot.next(workPackage('1', 'New subject'));
    second.resolve();
    await settled();
    first.resolve();
    await settled();
    await fixture.whenStable();

    expect(fixture.componentInstance.workPackage.subject).toBe('New subject');
    expect(screen.getByTestId('work-package').textContent).toBe('New subject');
  });

  it('holds numeric cache slot emissions until their schema is loaded', async () => {
    ensureLoaded.mockResolvedValueOnce({} as SchemaResource);
    await render('PROJ-1');

    semanticSlot.next(workPackage('1', 'Landing page'));
    await settled();

    const schema = deferred();
    ensureLoaded.mockReturnValue(schema.promise);
    numericSlot.next(workPackage('1', 'Renamed'));
    await settled();

    expect(fixture.componentInstance.workPackage.subject).toBe('Landing page');

    schema.resolve();
    await settled();

    expect(fixture.componentInstance.workPackage.subject).toBe('Renamed');
  });

  it('keeps a fresh semantic result over an older numeric cache copy', async () => {
    ensureLoaded.mockResolvedValue({} as SchemaResource);
    const replayingNumericSlot = new BehaviorSubject(workPackage('1', 'List copy'));
    numericSlot = replayingNumericSlot;
    await render('PROJ-1');

    semanticSlot.next(workPackage('1', 'Fresh'));
    await settled();
    await fixture.whenStable();

    expect(fixture.componentInstance.workPackage.subject).toBe('Fresh');
  });

  it('reports a schema failure instead of rendering, then retries on the next emission', async () => {
    const failure = new Error('schema unavailable');
    ensureLoaded
      .mockRejectedValueOnce(failure)
      .mockResolvedValueOnce({} as SchemaResource);
    await render();

    semanticSlot.next(workPackage('1', 'Landing page'));
    await settled();
    await fixture.whenStable();

    expect(handleRawError).toHaveBeenCalledWith(failure);
    expect(screen.queryByTestId('work-package')).toBeNull();

    semanticSlot.next(workPackage('1', 'Landing page'));
    await settled();
    await fixture.whenStable();

    expect(screen.getByTestId('work-package').textContent).toBe('Landing page');
  });

  it('drops a pending work package after destroy', async () => {
    const schema = deferred();
    ensureLoaded.mockReturnValue(schema.promise);
    await render();

    semanticSlot.next(workPackage('1', 'Landing page'));
    fixture.destroy();
    schema.resolve();
    await settled();

    expect(fixture.componentInstance.workPackage).toBeUndefined();
  });
});
