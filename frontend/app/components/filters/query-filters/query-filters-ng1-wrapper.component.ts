//-- copyright
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
//++

// This Angular directive will act as an interface to the "upgraded" AngularJS component
// query-filters
import {
  Directive, DoCheck, ElementRef, Inject, Injector, OnChanges, OnDestroy,
  OnInit, SimpleChanges
} from '@angular/core';
import {UpgradeComponent} from '@angular/upgrade/static';

@Directive({selector: 'ng1-query-filters-wrapper'})
export class Ng1QueryFiltersComponentWrapper extends UpgradeComponent implements OnInit, OnChanges, DoCheck, OnDestroy {

  constructor(@Inject(ElementRef) elementRef:ElementRef, @Inject(Injector) injector:Injector) {
    // We must pass the name of the directive as used by AngularJS to the super
    super('queryFilters', elementRef, injector);
  }

  // For this class to work when compiled with AoT, we must implement these lifecycle hooks
  // because the AoT compiler will not realise that the super class implements them
  ngOnInit() { super.ngOnInit(); }

  ngOnChanges(changes:SimpleChanges) { super.ngOnChanges(changes); }

  ngDoCheck() { super.ngDoCheck(); }

  ngOnDestroy() { super.ngOnDestroy(); }
}
