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

import {Component, Injector, NgModuleFactoryLoader, OnInit} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {DynamicLazyLoadModule} from "core-app/modules/common/dynamic-embedding/dynamic-embeddable-module.interface";

@Component({
  selector: 'wp-embedded-calendar',
  template: `
    <ng-container *ngIf="!!embeddedComponent">
      <ng-container *ngComponentOutlet="embeddedComponent; injector: embeddedInjector"></ng-container>
    </ng-container>
    <ndc-dynamic *ngIf="false && !!embeddedComponent"
                 [ndcDynamicComponent]="embeddedComponent"
                 [ndcDynamicInjector]="embeddedInjector"
                 [ndcDynamicInputs]="{ static: true }">
    </ndc-dynamic>
  `
})
export class WorkPackagesEmbeddedCalendarEntryComponent implements OnInit {
  public embeddedComponent:any;
  public embeddedInjector:Injector;

  constructor(private readonly loader:NgModuleFactoryLoader,
              private readonly injector:Injector) {
  }

  ngOnInit() {
    this.loader.load('core-app/modules/calendar/openproject-calendar.module#OpenprojectCalendarModule')
      .then(factory => {
        const moduleRef = factory.create(this.injector);
        const module = moduleRef.instance as DynamicLazyLoadModule;
        this.embeddedInjector = moduleRef.injector;
        this.embeddedComponent = module.lazyloadableComponents.calendar;
      });
  }
}

DynamicBootstrapper.register({ selector: 'wp-embedded-calendar', cls: WorkPackagesEmbeddedCalendarEntryComponent });
