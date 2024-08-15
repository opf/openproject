import { AfterViewInit, Component, ElementRef, OnInit } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  ExternalRelationQueryConfigurationService,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-relation-query-configuration.service';
import { DomAutoscrollService } from 'core-app/shared/helpers/drag-and-drop/dom-autoscroll.service';
import { DragulaService, DrakeWithModels } from 'ng2-dragula';
import { GonService } from 'core-app/core/gon/gon.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { installMenuLogic } from 'core-app/core/setup/globals/global-listeners/action-menu';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { TypeBannerService } from 'core-app/features/admin/types/type-banner.service';

export type TypeGroupType = 'attribute'|'query';

export interface TypeFormAttribute {
  key:string;
  translation:string;
  is_cf:boolean;
}

export interface TypeGroup {
  /** original internal key, if any */
  key:string|null|undefined;
  /** Localized / given name */
  name:string;
  attributes:TypeFormAttribute[];
  query?:any;
  type:TypeGroupType;
}

export const emptyTypeGroup = '__empty';

@Component({
  selector: 'opce-admin-type-form-configuration',
  templateUrl: './type-form-configuration.html',
  providers: [
    TypeBannerService,
  ],
})
export class TypeFormConfigurationComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  public text = {
    drag_to_activate: this.I18n.t('js.admin.type_form.drag_to_activate'),
    reset: this.I18n.t('js.admin.type_form.reset_to_defaults'),
    label_group: this.I18n.t('js.label_group'),
    new_group: this.I18n.t('js.admin.type_form.new_group'),
    label_inactive: this.I18n.t('js.admin.type_form.inactive'),
    custom_field: this.I18n.t('js.admin.type_form.custom_field'),
    add_group: this.I18n.t('js.admin.type_form.add_group'),
    add_table: this.I18n.t('js.admin.type_form.add_table'),
  };

  private autoscroll:any;

  private element:HTMLElement;

  private form:JQuery;

  private submit:JQuery;

  public groups:TypeGroup[] = [];

  public inactives:TypeFormAttribute[] = [];

  private attributeDrake:DrakeWithModels;

  private groupsDrake:DrakeWithModels;

  private no_filter_query:string;

  constructor(
    private elementRef:ElementRef,
    private I18n:I18nService,
    private Gon:GonService,
    private dragula:DragulaService,
    private confirmDialog:ConfirmDialogService,
    private toastService:ToastService,
    private externalRelationQuery:ExternalRelationQueryConfigurationService,
    readonly typeBanner:TypeBannerService,
  ) {
    super();
  }

  ngOnInit():void {
    // Hook on form submit
    this.element = this.elementRef.nativeElement;
    this.no_filter_query = this.element.dataset.noFilterQuery!;
    this.form = jQuery(this.element).closest('form');
    this.submit = this.form.find('.form-configuration--save');

    // In the following we are triggering the form submit ourselves to work around
    // a firefox shortcoming. But to avoid double submits which are sometimes not canceled fast
    // enough, we need to memoize whether we have already submitted.
    let submitted = false;

    this.form.on('submit', () => {
      submitted = true;
    });

    // Capture mousedown on button because firefox breaks blur on click
    this.submit.on('mousedown', () => {
      setTimeout(() => {
        if (!submitted) {
          this.form.trigger('submit');
        }
      }, 50);
      return true;
    });

    // Capture regular form submit
    this.form.on('submit.typeformupdater', () => {
      this.updateHiddenFields();
      return true;
    });

    // Setup groups
    this.groupsDrake = this
      .dragula
      .createGroup('groups', {
        moves: (el, source, handle:HTMLElement) => handle.classList.contains('group-handle'),
      })
      .drake;

    // Setup attributes
    this.attributeDrake = this
      .dragula
      .createGroup('attributes', {
        moves: (el, source, handle:HTMLElement) => handle.classList.contains('attribute-handle'),
      })
      .drake;

    // Get attribute id
    this.groups = JSON
      .parse(this.element.dataset.activeGroups!)
      .filter((group:TypeGroup) => group?.key !== emptyTypeGroup);
    this.inactives = JSON.parse(this.element.dataset.inactiveAttributes!);

    // Setup autoscroll
    const that = this;
    this.autoscroll = new DomAutoscrollService(
      [
        document.getElementById('content-body')!,
      ],
      {
        margin: 25,
        maxSpeed: 10,
        scrollWhenOutside: true,
        autoScroll(this:any) {
          const groups = that.groupsDrake && that.groupsDrake.dragging;
          const attributes = that.attributeDrake && that.attributeDrake.dragging;

          return groups || attributes;
        },
      },
    );
  }

  ngAfterViewInit():void {
    const menu = jQuery(this.elementRef.nativeElement).find('.toolbar-items');
    installMenuLogic(menu);
  }

  deactivateAttribute(attribute:TypeFormAttribute):void {
    this.updateInactives(this.inactives.concat(attribute));
  }

  addGroupAndOpenQuery():void {
    const newGroup = this.createGroup('query');
    this.editQuery(newGroup);
  }

  editQuery(group:TypeGroup):void {
    this.typeBanner.conditional(
      () => this.typeBanner.showEEOnlyHint(),
      () => {
        // Disable display mode and timeline for now since we don't want users to enable it
        const disabledTabs = {
          'display-settings': I18n.t('js.work_packages.table_configuration.embedded_tab_disabled'),
          timelines: I18n.t('js.work_packages.table_configuration.embedded_tab_disabled'),
        };

        this.externalRelationQuery.show({
          currentQuery: JSON.parse(group.query),
          callback: (queryProps:any) => (group.query = JSON.stringify(queryProps)),
          disabledTabs,
        });
      },
    );
  }

  deleteGroup(group:TypeGroup):void {
    this.typeBanner.conditional(
      () => this.typeBanner.showEEOnlyHint(),
      () => {
        if (group.type === 'attribute') {
          this.updateInactives(this.inactives.concat(group.attributes));
        }

        this.groups = this.groups.filter((el) => el !== group);

        return group;
      },
    );
  }

  createGroup(type:TypeGroupType, groupName = ''):TypeGroup {
    const group:TypeGroup = {
      type,
      name: groupName,
      key: null,
      query: this.no_filter_query,
      attributes: [],
    };

    this.groups.unshift(group);
    return group;
  }

  resetToDefault($event:Event):boolean {
    this.confirmDialog
      .confirm({
        text: {
          title: this.I18n.t('js.types.attribute_groups.reset_title'),
          text: this.I18n.t('js.types.attribute_groups.confirm_reset'),
          button_continue: this.I18n.t('js.label_reset'),
        },
      })
      .then(() => {
        this.form.find('input#type_attribute_groups').val(JSON.stringify([]));

        // Disable our form handler that updates the attribute groups
        this.form.off('submit.typeformupdater');
        this.form.trigger('submit');
      })
      .catch(() => {
      });

    $event.preventDefault();
    return false;
  }

  private updateInactives(newValue:TypeFormAttribute[]):void {
    this.inactives = [...newValue].sort((a, b) => a.translation.localeCompare(b.translation));
  }

  // We maintain an empty group
  // that gets hidden in the frontend in case the user
  // decides to remove all groups
  // This was necessary since the "default" is actually an empty array of groups
  private get emptyGroup():TypeGroup {
    return {
      type: 'attribute', key: emptyTypeGroup, name: 'empty', attributes: [],
    };
  }

  private updateHiddenFields():void {
    const hiddenField = this.form.find('.admin-type-form--hidden-field');
    if (this.groups.length === 0) {
      // Ensure we're adding an empty group if deliberately removing
      // all values.
      hiddenField.val(JSON.stringify([this.emptyGroup]));
    } else {
      hiddenField.val(JSON.stringify(this.groups));
    }
  }
}
