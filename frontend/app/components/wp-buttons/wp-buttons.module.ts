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

import {opDirective} from '../open-project.module';

export interface ButtonControllerText {
  activate:string;
  deactivate:string;
  label:string;
  buttonText:string;
}

export abstract class WorkPackageButtonController {
  public disabled:boolean;
  public buttonId:string;
  public iconClass:string;

  public accessKey:number;

  protected text:ButtonControllerText;

  constructor(public I18n:op.I18n) {
    this.text = {
      activate: this.I18n.t('js.label_activate'),
      deactivate: this.I18n.t('js.label_deactivate'),
      label: this.labelKey ? this.I18n.t(this.labelKey) : '',
      buttonText: this.textKey ? this.I18n.t(this.textKey) : ''
    };
  }

  public get label():string {
    return this.text.label;
  }

  public get buttonText():string {
    return this.text.buttonText;
  }

  public get labelKey():string {
    return '';
  }

  public get textKey():string {
    return '';
  }

  protected get activationPrefix():string {
    return !this.isActive() ? this.text.activate + ' ' : '';
  }

  protected get deactivationPrefix():string {
    return this.isActive() ? this.text.deactivate + ' ' : '';
  }

  protected get prefix():string {
    return this.activationPrefix || this.deactivationPrefix;
  }

  public isToggle():boolean {
    return false;
  }

  public abstract isActive():boolean;

  public abstract performAction():void;
}

export abstract class WorkPackageNavigationButtonController extends WorkPackageButtonController {
  public activeState:string;
  public accessKey:number;

  constructor(public $state:ng.ui.IStateService, public I18n:op.I18n) {
    super(I18n);
  }

  public get label():string {
    return this.activationPrefix + this.text.label;
  }

  public get activeAccessKey():number | void {
    if (!this.isActive()) return this.accessKey;
  }

  public isActive():boolean {
    return this.$state.includes(this.activeState);
  }
}

export function wpButtonDirective(config:Object):ng.IDirective {
  return opDirective({
    restrict: 'E',
    templateUrl: '/components/wp-buttons/wp-button.template.html',

    scope: {
      disabled: '=?'
    },

    controllerAs: 'vm',
    bindToController: true
  }, config);
}
