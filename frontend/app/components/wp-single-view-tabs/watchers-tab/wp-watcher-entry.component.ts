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

import {Component, Inject, Input, OnInit} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {WorkPackageWatchersTabComponent} from './watchers-tab.component';
import {UserResource} from '../../api/api-v3/hal-resources/user-resource.service';

@Component({
  templateUrl: './wp-watcher-entry.html',
  selector: 'wp-watcher-entry',
})
export class WorkPackageWatcherEntryComponent implements OnInit {
  @Input('watcher') public watcher:UserResource;
  public deleting = false;
  public text:{ remove:string };

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
              readonly panelCtrl:WorkPackageWatchersTabComponent) {
  }

  ngOnInit() {
    this.text = {
      remove: this.I18n.t('js.label_remove_watcher', { name: this.watcher.name })
    };
  }

  public remove() {
    this.deleting = true;
    this.panelCtrl.removeWatcher(this.watcher);
  }
}
