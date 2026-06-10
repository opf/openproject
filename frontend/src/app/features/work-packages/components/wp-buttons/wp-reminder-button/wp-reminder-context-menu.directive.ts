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
