// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component, ElementRef, EventEmitter, Input, OnInit, Output, ViewChild} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {NgSelectComponent} from "@ng-select/ng-select/dist";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {concat, Observable, of, Subject} from "rxjs";
import {catchError, debounceTime, distinctUntilChanged, map, switchMap, tap} from "rxjs/operators";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";

@Component({
  template: `
    <ng-select [items]="options$ | async"
               bindLabel="name"
               bindValue="id"
               [ngModel]="initialSelection"
               [virtualScroll]="true"
               [trackByFn]="userTracker"
               [typeahead]="searchInput$"
               [loading]="searchLoading"
               (focus)="onFocus()"
               (change)="onModelChange($event)">
      <ng-template ng-option-tmp let-item="item" let-index="index">
        <user-avatar *ngIf="item"
                     [user]="item"
                     data-class-list="avatar-mini">
        </user-avatar>
        {{ item.name }}
      </ng-template>
    </ng-select>
  `,
  selector: 'user-autocompleter'
})
export class UserAutocompleterComponent implements OnInit {
  userTracker = (item:any) => item.href;

  @ViewChild(NgSelectComponent, {static: true}) public ngSelectComponent:NgSelectComponent;
  @Output() public onChange = new EventEmitter<void>();
  @Input() public clearAfterSelection:boolean = false;

  // Load all users as default
  @Input() public url:string = this.pathHelper.api.v3.users.path;
  @Input() public allowEmpty:boolean = false;


  @Input() public initialSelection:number|null = null;

  // Update an input field after changing, used when externally loaded
  private updateInputField:HTMLInputElement|undefined;

  // Observable to the option results
  public options$:Observable<any[]>;
  public searchLoading:boolean = false;
  public searchInput$ = new Subject<string>();

  constructor(protected elementRef:ElementRef,
              protected halResourceService:HalResourceService,
              protected I18n:I18nService,
              readonly pathHelper:PathHelperService) {
  }

  ngOnInit() {
    const input = this.elementRef.nativeElement.dataset['updateInput'];
    const allowEmpty = this.elementRef.nativeElement.dataset['allowEmpty'];
    if (input) {
      this.updateInputField = document.getElementsByName(input)[0] as HTMLInputElement|undefined;
      this.setInitialSelection();
    }

    if (allowEmpty === 'true') {
      this.allowEmpty = true;
    }

    this.options$ = concat(
      of([]),
      this.searchInput$.pipe(
        debounceTime(200),
        distinctUntilChanged(),
        tap(() => this.searchLoading = true),
        switchMap(term =>
          this.getAvailableUsers(this.url, term)
            .pipe(
              catchError(() => of([])),
              tap(() => this.searchLoading = false)
            )
        )
      )
    );
  }

  public onFocus() {
    this.searchInput$.next('');
  }

  public onModelChange(user:any) {
    if (user) {
      this.onChange.emit(user);
      this.searchInput$.next('');

      if (this.clearAfterSelection) {
        this.ngSelectComponent.clearItem(user);
      }

      if (this.updateInputField) {
        this.updateInputField.value = user.id;
      }
    }
  }

  private getAvailableUsers(url:string, searchTerm:any):Observable<any[]> {
    let filters = new ApiV3FilterBuilder();

    if (searchTerm) {
      filters.add('name', '~', [searchTerm]);
    }

    return this.halResourceService
      .get(url, { filters: filters.toJson() })
      .pipe(
        map(res => {
          let options = res.elements.map((el:any) => {
            return {name: el.name, id: el.id, href: el.href, avatar: el.avatar};
          });

          if (this.allowEmpty) {
            options.unshift({name: this.I18n.t('js.timelines.filter.noneSelection'), href: null, id: null});
          }

          return options;
        })
      );
  }

  private setInitialSelection() {
    if (this.updateInputField) {
      const id = parseInt(this.updateInputField.value);
      this.initialSelection = isNaN(id) ? null : id;
    }
  }
}

DynamicBootstrapper.register({selector: 'user-autocompleter', cls: UserAutocompleterComponent});
