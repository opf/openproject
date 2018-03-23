//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
//++

import {
  Component, Directive, ElementRef, Injector, Input, Output,
  SimpleChanges
} from '@angular/core';
import {UpgradeComponent} from '@angular/upgrade/static';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

@Directive({
  selector: 'activity-entry-upgraded'
})
export class ActivityEntryDirectiveUpgraded extends UpgradeComponent {
  @Input('workPackage') public workPackage:WorkPackageResource;
  @Input('activity') public activity:HalResource;
  @Input('activityNo') public activityNo:number;
  @Input('isInitial') public isInitial:boolean;
  @Input('inputElementId') public inputElementId:string;

  constructor(elementRef:ElementRef, injector:Injector) {
    super('activityEntry', elementRef, injector);
  }

  // For this class to work when compiled with AoT, we must implement these lifecycle hooks
  // because the AoT compiler will not realise that the super class implements them
  ngOnInit() { super.ngOnInit(); }

  ngOnChanges(changes:SimpleChanges) { super.ngOnChanges(changes); }

  ngDoCheck() { super.ngDoCheck(); }

  ngOnDestroy() { super.ngOnDestroy(); }
}

