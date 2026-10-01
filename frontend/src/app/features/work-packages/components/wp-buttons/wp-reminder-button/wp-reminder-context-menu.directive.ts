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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Directive, Input, OnInit, inject } from '@angular/core';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageReminderModalComponent } from 'core-app/features/work-packages/components/wp-reminder-modal/wp-reminder.modal';
import { ReminderPreset, REMINDER_PRESET_OPTIONS } from 'core-app/features/work-packages/components/wp-reminder-modal/reminder.types';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[wpReminderContextMenu]',
  standalone: false,
})
export class WorkPackageReminderContextMenuDirective extends OpContextMenuTrigger implements OnInit {
  readonly I18n = inject(I18nService);
  readonly opModalService = inject(OpModalService);

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('wpReminderContextMenu-workPackage') workPackage:WorkPackageResource;

  protected items:OpContextMenuItem[] = [];

  ngOnInit() {
    this.buildItems();
  }

  public get locals() {
    return {
      items: this.items,
      contextMenuId: 'reminder-dropdown-menu',
      label: this.I18n.t('js.work_packages.reminders.title.new'),
    };
  }

  private buildItems() {
    this.items = [
      {
        isHeader: true,
        linkText: this.I18n.t('js.work_packages.reminders.title.new'),
      },
      ...this.buildPresetItems(),
    ];
  }

  private buildPresetItems() {
    return REMINDER_PRESET_OPTIONS.map((preset) => ({
      disabled: false,
      linkText: this.I18n.t(`js.work_packages.reminders.presets.${preset}`),
      onClick: () => {
        this.openModal(preset);
        return true;
      },
    }));
  }

  private openModal(preset:ReminderPreset):void {
    this.opModalService.show(
      WorkPackageReminderModalComponent,
      'global',
      {
        workPackage: this.workPackage,
        preset,
      },
      false,
      true,
    );
  }
}
