import {Component, ElementRef, OnInit} from '@angular/core';
import {TypeBannerService} from 'core-app/modules/admin/types/type-banner.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {ExternalRelationQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-relation-query-configuration.service';
import {DomAutoscrollService} from 'core-app/modules/common/drag-and-drop/dom-autoscroll.service';
import {DragulaService} from 'ng2-dragula';
import {ConfirmDialogService} from 'core-components/modals/confirm-dialog/confirm-dialog.service';
import {Drake} from 'dragula';
import {GonService} from "core-app/modules/common/gon/gon.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

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

export const adminTypeFormConfigurationSelector = 'admin-type-form-configuration';

@Component({
  selector: adminTypeFormConfigurationSelector,
  templateUrl: './type-form-configuration.html',
  providers: [
    TypeBannerService,
  ]
})
export class TypeFormConfigurationComponent extends UntilDestroyedMixin implements OnInit {

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

  private attributeDrake:Drake;
  private groupsDrake:Drake;

  private no_filter_query:string;

  constructor(private elementRef:ElementRef,
              private I18n:I18nService,
              private Gon:GonService,
              private dragula:DragulaService,
              private confirmDialog:ConfirmDialogService,
              private notificationsService:NotificationsService,
              private externalRelationQuery:ExternalRelationQueryConfigurationService) {
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

    this.form.on('submit', (event) => {
      submitted = true;
    });

    // Capture mousedown on button because firefox breaks blur on click
    this.submit.on('mousedown', (event) => {
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
    this.dragula.createGroup('groups', {
      moves: (el, source, handle:HTMLElement) => handle.classList.contains('group-handle')
    });

    // Setup attributes
    this.dragula.createGroup('attributes', {
      moves: (el, source, handle:HTMLElement) => handle.classList.contains('attribute-handle')
    });

    this.dragula.dropModel("attributes")
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((event) => {
        console.log(event);
      });

    // Get attribute id
    this.groups = JSON.parse(this.element.dataset.activeGroups!);
    this.inactives = JSON.parse(this.element.dataset.inactiveAttributes!);

    // Setup autoscroll
    const that = this;
    this.autoscroll = new DomAutoscrollService(
      [
        document.getElementById('content-wrapper')!
      ],
      {
        margin: 25,
        maxSpeed: 10,
        scrollWhenOutside: true,
        autoScroll: function (this:any) {
          const groups = that.groupsDrake && that.groupsDrake.dragging;
          const attributes = that.attributeDrake && that.attributeDrake.dragging;
          return this.down && (groups || attributes);
        }
      });
  }

  public deactivateAttribute(attribute:TypeFormAttribute) {
    this.updateInactives(this.inactives.concat(attribute));
  }

  public addGroupAndOpenQuery():void {
    let newGroup = this.createGroup('query');
    this.editQuery(newGroup);
  }

  public editQuery(group:TypeGroup) {
    // Disable display mode and timeline for now since we don't want users to enable it
    const disabledTabs = {
      'display-settings': I18n.t('js.work_packages.table_configuration.embedded_tab_disabled'),
      'timelines': I18n.t('js.work_packages.table_configuration.embedded_tab_disabled')
    };

    this.externalRelationQuery.show(
      JSON.parse(group.query),
      (queryProps:any) => group.query = JSON.stringify(queryProps),
      disabledTabs
    );
  }

  public deleteGroup(group:TypeGroup) {
    if (group.type === 'attribute') {
      this.updateInactives(this.inactives.concat(group.attributes));
    }

    this.groups = this.groups.filter(el => el !== group);

    return group;
  }

  public createGroup(type:TypeGroupType, groupName:string = '') {
    let group:TypeGroup = {
      type: type,
      name: '',
      key: null,
      query: this.no_filter_query,
      attributes: [],
    };

    this.groups.unshift(group);
    return group;
  }

  public resetToDefault($event:Event):boolean {
    this.confirmDialog
      .confirm({
        text: {
          title: this.I18n.t('js.types.attribute_groups.reset_title'),
          text: this.I18n.t('js.types.attribute_groups.confirm_reset'),
          button_continue: this.I18n.t('js.label_reset')
        }
      })
      .then(() => {
        this.form.find('input#type_attribute_groups').val(JSON.stringify([]));

        // Disable our form handler that updates the attribute groups
        this.form.off('submit.typeformupdater');
        this.form.trigger('submit');
      });

    $event.preventDefault();
    return false;
  }

  private updateInactives(newValue:TypeFormAttribute[]) {
    this.inactives = [...newValue].sort((a, b) => a.translation.localeCompare(b.translation));
  }

  private updateHiddenFields() {
    const hiddenField = this.form.find('.admin-type-form--hidden-field');
    hiddenField.val(JSON.stringify(this.groups));
  }
}

