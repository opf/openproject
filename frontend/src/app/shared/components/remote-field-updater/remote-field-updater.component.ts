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

import { debounce } from 'lodash-es';
import { ChangeDetectionStrategy, Component, ElementRef, OnDestroy, OnInit, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export const remoteFieldUpdaterSelector = 'remote-field-updater';

@Component({
  selector: remoteFieldUpdaterSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '',
  standalone: false,
})
export class RemoteFieldUpdaterComponent implements OnInit, OnDestroy {
  private elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  private http = inject(HttpClient);


  private url:string;

  private form:HTMLFormElement;

  private debouncedUpdaterBound:EventListener;

  private spentOnTextField:HTMLInputElement | null = null;
  private costTypeSelect:HTMLInputElement | null = null;
  private unitsTextField:HTMLInputElement | null = null;

  ngOnInit():void {
    const element = this.elementRef.nativeElement;
    this.form = element.closest('form')!;
    this.costTypeSelect = this.form.querySelector('#cost_entry_cost_type_id');
    this.unitsTextField = this.form.querySelector('#cost_entry_units');

    this.url = element.dataset.url!;

    this.debouncedUpdaterBound = debounce(this.updater.bind(this), 500);

    this.addListeners();
  }

  ngOnDestroy():void {
    this.removeListeners();
  }

  private addListeners() {
    this.addEventListenerWhenSpentOnFieldIsAdded('input', this.debouncedUpdaterBound);
    this.costTypeSelect?.addEventListener('change', this.debouncedUpdaterBound);
    this.unitsTextField?.addEventListener('input', this.debouncedUpdaterBound);
  }

  private removeListeners() {
    if (this.debouncedUpdaterBound && 'cancel' in this.debouncedUpdaterBound) {
      (this.debouncedUpdaterBound as { cancel:() => void }).cancel();
    }
    this.spentOnTextField?.removeEventListener('input', this.debouncedUpdaterBound);
    this.costTypeSelect?.removeEventListener('change', this.debouncedUpdaterBound);
    this.unitsTextField?.removeEventListener('input', this.debouncedUpdaterBound);
  }

  private addEventListenerWhenSpentOnFieldIsAdded(type:string, eventListener:EventListener) {
    // Use MutationObserver to watch for the addition of the spent_on input
    // field. This input field is a date picker.
    const observer = new MutationObserver((mutations) => {
      mutations
        .filter((mutation) => mutation.type === 'childList')
        .forEach(() => {
          if (this.spentOnTextField === null && this.form.querySelector('#cost_entry_spent_on')) {
            this.spentOnTextField = this.form.querySelector('#cost_entry_spent_on')!;
            this.spentOnTextField.addEventListener(type, eventListener);
            observer.disconnect(); // Stop observing once the element is found and listener is added
          }
        });
    });
    observer.observe(this.form, { childList: true, subtree: true });
  }

  private request(params:Record<string, string>) {
    const headers:Record<string, string> = {};

    headers.Accept = 'application/json';

    return this.http
      .get(
        this.url,
        {
          params,
          headers,
          responseType: 'json',
          withCredentials: true,
        },
      );
  }

  private updater() {
    const params:Record<string, string> = {};

    // Gather request keys
    this
      .form
      .querySelectorAll('.remote-field--input')
      .forEach((el:HTMLInputElement) => {
        params[el.dataset.remoteFieldKey!] = el.value;
      });

    this
      .request(params)
      .subscribe((response:object) => {
        Object.entries(response).forEach(([selector, val]) => {
          const element = document.getElementById(selector) as HTMLElement|HTMLInputElement;

          if (element instanceof HTMLInputElement) {
            element.value = val;
          } else if (element) {
            element.textContent = val;
          }
        });
      });
  }
}
