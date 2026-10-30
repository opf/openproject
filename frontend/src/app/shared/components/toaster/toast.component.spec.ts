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
import { TestBed } from '@angular/core/testing';
import { HttpEvent, HttpResponse } from '@angular/common/http';
import { Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { ToastComponent } from './toast.component';
import { IToast, ToastService } from './toast.service';
import { UploadProgressComponent } from './upload-progress.component';

describe('ToastComponent branch data', () => {
  const remove = vi.fn();

  function setup(toast:IToast) {
    TestBed.configureTestingModule({
      imports: [CommonModule, IconModule],
      declarations: [ToastComponent, UploadProgressComponent, OpIconComponent],
      providers: [
        { provide: ToastService, useValue: { remove } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });
    const fixture = TestBed.createComponent(ToastComponent);
    fixture.componentRef.setInput('toast', toast);
    fixture.detectChanges();
    return { fixture, component: fixture.componentInstance, host: fixture.nativeElement as HTMLElement };
  }

  beforeEach(() => remove.mockClear());

  it('renders error messages and removes the original toast', () => {
    const toast:IToast = { type: 'error', message: 'Failed', data: ['first', 'second'] };
    const { host, component } = setup(toast);
    expect(Array.from(host.querySelectorAll('li')).map((li) => li.textContent)).toEqual(['first', 'second']);
    expect(component.data).toBe(toast.data);
    host.querySelector<HTMLButtonElement>('.op-toast--close')!.click();
    expect(remove).toHaveBeenCalledWith(toast);
  });

  it.each(['success', 'warning', 'info'] as const)('renders %s without array data', (type) => {
    const { host } = setup({ type, message: 'Message' });
    expect(host.textContent).toContain('Message');
    expect(host.querySelectorAll('li')).toHaveLength(0);
  });

  it('allows a message-only error event', () => {
    const { host } = setup({ type: 'error', message: 'Failed' });
    expect(host.querySelectorAll('li')).toHaveLength(0);
  });

  it('renders upload tuples and counts completion', () => {
    const upload = new Subject<HttpEvent<unknown>>();
    const data = [[new File([], 'report.txt'), upload]];
    const { host, component, fixture } = setup({ type: 'upload', message: 'Uploading', data });
    expect(host.textContent).toContain('report.txt');
    expect(component.data).toBe(data);
    expect(component.removable).toBe(false);
    upload.next(new HttpResponse({ body: {} }));
    fixture.detectChanges();
    expect(component.uploadCount).toBe(1);
    fixture.destroy();
    expect(upload.observed).toBe(false);
  });

  it('collapses more than five uploads and removes the toast on upload error', () => {
    const upload = new Subject<HttpEvent<unknown>>();
    const data = Array.from({ length: 6 }, (_, i) => [new File([], `${i}.txt`), upload]);
    const toast:IToast = { type: 'upload', message: 'Uploading', data };
    const { component } = setup(toast);
    expect(component.canBeHidden).toBe(true);
    upload.error(new Error('upload failed'));
    expect(remove).toHaveBeenCalledWith(toast);
  });

  it('finishes loading on the first emission', () => {
    const loading = new Subject<unknown>();
    const toast:IToast = { type: 'loading', message: 'Loading', data: loading };
    const { component } = setup(toast);
    expect(component.data).toBe(loading);
    expect(component.loading$.value).toBe(true);
    loading.next('done');
    expect(component.loading$.value).toBe(false);
    expect(remove).toHaveBeenCalledExactlyOnceWith(toast);
    expect(loading.observed).toBe(false);
  });

  it('preserves loading completion after the component is destroyed', () => {
    const loading = new Subject<unknown>();
    const toast:IToast = { type: 'loading', message: 'Loading', data: loading };
    const { component, fixture } = setup(toast);
    fixture.destroy();
    expect(loading.observed).toBe(true);
    loading.complete();
    expect(component.loading$.value).toBe(false);
    expect(remove).toHaveBeenCalledExactlyOnceWith(toast);
  });
});
