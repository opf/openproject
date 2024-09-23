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

import { StateService, TransitionService } from '@uirouter/core';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { Observable } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { take } from 'rxjs/operators';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';

@Component({
  selector: 'wp-create-button',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './wp-create-button.html',
})
export class WorkPackageCreateButtonComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input('allowed') allowedWhen:string[];

  @Input('stateName$') stateName$:Observable<string>;

  allowed:boolean;

  disabled:boolean;

  projectIdentifier:string|null;

  types:any;

  transitionUnregisterFn:Function;

  text = {
    title: this.I18n.t('js.work_packages.create.title'),
    createWithDropdown: this.I18n.t('js.work_packages.create.button'),
    createButton: this.I18n.t('js.label_work_package'),
    explanation: this.I18n.t('js.label_create_work_package'),
  };

  constructor(
    readonly $state:StateService,
    readonly currentUser:CurrentUserService,
    readonly currentProject:CurrentProjectService,
    readonly authorisationService:AuthorisationService,
    readonly transition:TransitionService,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  ngOnInit() {
    this.projectIdentifier = this.currentProject.identifier;

    // Find the first permission that is allowed
    this.currentUser
      .hasCapabilities$('work_packages/create', this.currentProject.id)
      .pipe(
        take(1),
      )
      .subscribe((allowed) => {
        this.allowed = allowed;
        this.updateDisabledState();
      });

    this.transitionUnregisterFn = this.transition.onSuccess({}, this.updateDisabledState.bind(this));
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.transitionUnregisterFn();
  }

  private updateDisabledState() {
    this.disabled = !this.allowed || this.$state.includes('**.new');
    this.cdRef.detectChanges();
  }
}
