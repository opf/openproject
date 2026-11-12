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
import { HttpClient } from '@angular/common/http';
import { By } from '@angular/platform-browser';
import { TestBed } from '@angular/core/testing';
import { BehaviorSubject, ReplaySubject } from 'rxjs';
import { within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { SpotTooltipComponent } from 'core-app/spot/components/tooltip/tooltip.component';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { StorageInformationService } from '../storage-information/storage-information.service';
import { StorageInformationComponent } from '../storage-information/storage-information.component';
import { StorageInformationBox } from '../storage-information/storage-information-box';
import { FileLinkListItemComponent } from '../file-link-list-item/file-link-list-item.component';
import { nextcloud, storageConnected, fileLinkViewAllowed } from '../storages-constants.const';
import { WorkPackageFilesTabComponent } from 'core-app/features/work-packages/components/wp-single-view-tabs/files-tab/op-files-tab.component';
import { OpAttachmentsComponent } from 'core-app/shared/components/attachments/attachments.component';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { ProjectStoragesResourceService } from 'core-app/core/state/project-storages/project-storages.service';
import { IProjectStorage } from 'core-app/core/state/project-storages/project-storage.model';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { StorageComponent } from './storage.component';

describe('StorageComponent asynchronous template contracts', () => {
  const uploadName = 'js.storages.upload_files';
  const linkName = 'js.storages.link_existing_files';
  const loadedStorage:IStorage = {
    id: '1', name: 'Storage', _links: {
      self: { href: '/storages/1', title: 'Storage' }, type: { href: nextcloud, title: 'Nextcloud' },
      origin: { href: '/origin', title: 'Origin' }, open: { href: '/open', title: 'Open' },
      authorizationState: { href: storageConnected, title: 'Connected' }, prepareUpload: [],
    },
  };

  function configure() {
    const storage = new ReplaySubject<IStorage>(1);
    const projectStorages = new ReplaySubject<IProjectStorage[]>(1);
    const managePermission = new ReplaySubject<boolean>(1);
    const viewPermission = new ReplaySubject<boolean>(1);
    const request = vi.fn();
    const fileLinks = new BehaviorSubject<IFileLink[]>([]);
    const information = new BehaviorSubject<StorageInformationBox[]>([]);
    const translate = vi.fn((key:string, _options?:unknown) => key);
    TestBed.configureTestingModule({
      imports: [CommonModule, IconModule, OpTooltipDirective],
      declarations: [WorkPackageFilesTabComponent, OpAttachmentsComponent, StorageComponent, StorageInformationComponent, FileLinkListItemComponent, SpotTooltipComponent],
      providers: [
        { provide: HttpClient, useValue: {} },
        { provide: I18nService, useValue: { t: translate } },
        { provide: TimezoneService, useValue: {} },
        { provide: PathHelperService, useValue: { workPackageUpdateCounterPath: (id:string) => `/work_packages/${id}/counter` } },
        { provide: CurrentUserService, useValue: { hasCapabilities$: (capability:string) =>
          (capability === 'file_links/manage' ? managePermission : viewPermission) } },
        { provide: ProjectStoragesResourceService, useValue: { requireCollection: () => projectStorages } },
        { provide: TurboRequestsService, useValue: { request } },
        { provide: ToastService, useValue: {} },
        { provide: OpModalService, useValue: {} },
        { provide: PrincipalRendererService, useValue: { render: vi.fn() } },
        { provide: ConfirmDialogService, useValue: {} },
        { provide: StoragesResourceService, useValue: { requireEntity: () => storage } },
        { provide: FileLinksResourceService, useValue: { requireCollection: () => fileLinks } },
        { provide: StorageFilesResourceService, useValue: {} },
        { provide: StorageInformationService, useValue: { storageInformation: () => information } },
      ],
    });
    return { storage, fileLinks, information, translate, projectStorages, managePermission, viewPermission, request };
  }

  function create() {
    const fixture = TestBed.createComponent(StorageComponent);
    fixture.componentRef.setInput('resource', { id: '42', $links: { fileLinks: { href: '/work_packages/42/file_links' } } });
    fixture.componentRef.setInput('projectStorage', {
      _links: { storage: { href: '/storages/1', title: 'Storage' }, open: { href: '/storage/open' } },
    });
    fixture.detectChanges();
    const host = fixture.nativeElement as HTMLElement;
    return { fixture, host, view: within(host) };
  }

  function createFilesTab(workPackage:object) {
    const fixture = TestBed.createComponent(WorkPackageFilesTabComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    fixture.detectChanges();
    const host = fixture.nativeElement as HTMLElement;
    return { fixture, host, view: within(host) };
  }

  it('keeps delayed storage labels nullable and renders empty content after loading', () => {
    const { storage, translate } = configure();
    const { fixture, host, view } = create();

    expect(view.queryByRole('list')).not.toBeInTheDocument();
    expect(translate).toHaveBeenCalledWith('js.storages.open_storage', { storageType: null });

    storage.next(loadedStorage);
    fixture.detectChanges();

    expect(view.getAllByRole('button', { name: uploadName })).toHaveLength(2);
    expect(view.getByRole('button', { name: linkName })).toBeInTheDocument();

    fixture.componentRef.setInput('allowUploading', false);
    fixture.detectChanges();

    expect(host).toHaveTextContent('js.storages.file_links.empty');
  });

  it('preserves file-list rendering and storage-error controls', () => {
    const { storage, fileLinks, information } = configure();
    const { fixture, host, view } = create();
    const link = { href: '/file', title: 'Document' };

    storage.next(loadedStorage);
    fileLinks.next([{
      id: 'link-7', originData: { id: 'file-9', name: 'Document' },
      _links: { self: link, storage: link, container: link, creator: link, originOpen: link,
        staticOriginOpen: link, originOpenLocation: link, staticOriginOpenLocation: link,
        staticOriginDownload: link, status: { href: fileLinkViewAllowed, title: 'Allowed' } },
    }]);
    fixture.detectChanges();

    expect(within(view.getByRole('list')).getAllByRole('listitem')).toHaveLength(1);
    expect(host).toHaveTextContent('Document');

    information.next([new StorageInformationBox('warning', 'Permission denied', 'Cannot upload')]);
    fixture.detectChanges();

    expect(host).toHaveTextContent('Permission denied');
    expect(view.queryByRole('button', { name: uploadName })).not.toBeInTheDocument();
    expect(view.queryByRole('button', { name: linkName })).not.toBeInTheDocument();
  });

  it('keeps files-tab storage actions unavailable until management permission resolves', () => {
    const { projectStorages, managePermission, viewPermission, storage, request } = configure();
    const { fixture, host, view } = createFilesTab({
      id: '42', project: { id: '7' }, $links: { fileLinks: { href: '/work_packages/42/file_links' } },
    });
    const link = { href: '/storages/1', title: 'Storage' };

    expect(host.querySelector('op-storage')).not.toBeInTheDocument();

    projectStorages.next([{
      id: 'storage-7', projectFolderMode: 'inactive', projectFolderId: null,
      _links: { self: link, storage: link, project: link, creator: link },
    }]);
    storage.next(loadedStorage);
    viewPermission.next(true);
    fixture.detectChanges();

    expect(host.querySelector('op-storage')).toBeInTheDocument();
    expect(view.queryByRole('button', { name: uploadName })).not.toBeInTheDocument();
    expect(view.queryByRole('button', { name: linkName })).not.toBeInTheDocument();

    managePermission.next(true);
    fixture.detectChanges();

    expect(view.getAllByRole('button', { name: uploadName })).toHaveLength(2);
    expect(view.getByRole('button', { name: linkName })).toBeInTheDocument();

    const child = fixture.debugElement.query(By.directive(StorageComponent)).componentInstance as StorageComponent;
    child.fileAdded.emit();
    child.fileRemoved.emit();

    expect(request).toHaveBeenCalledTimes(2);
    expect(request).toHaveBeenCalledWith('/work_packages/42/counter');

    managePermission.next(false);
    fixture.detectChanges();

    expect(view.queryByRole('button', { name: uploadName })).not.toBeInTheDocument();
    expect(host).toHaveTextContent('js.storages.file_links.empty');

    projectStorages.next([]);
    fixture.detectChanges();

    expect(host.querySelector('op-storage')).not.toBeInTheDocument();
  });

  it('keeps files-tab requests absent when the project has no identifier', () => {
    configure();
    const permissions = vi.spyOn(TestBed.inject(CurrentUserService), 'hasCapabilities$');
    const collection = vi.spyOn(TestBed.inject(ProjectStoragesResourceService), 'requireCollection');

    const { host } = createFilesTab({ project: { id: null } });

    expect(permissions).not.toHaveBeenCalled();
    expect(collection).not.toHaveBeenCalled();
    expect(host.querySelector('op-storage')).not.toBeInTheDocument();
  });

  it('keeps upload services scoped to individual component instances', () => {
    configure();

    const first = create().fixture;
    const second = create().fixture;

    expect(first.debugElement.injector.get(OpUploadService)).not.toBe(second.debugElement.injector.get(OpUploadService));
  });
});
