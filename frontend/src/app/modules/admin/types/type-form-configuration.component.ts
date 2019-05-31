import {Component, ElementRef, OnInit} from '@angular/core';
import {TypeBannerService} from 'core-app/modules/admin/types/type-banner.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {ExternalRelationQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-relation-query-configuration.service';
import {DomAutoscrollService} from 'core-app/modules/common/drag-and-drop/dom-autoscroll.service';
import {DragulaService} from 'ng2-dragula';
import {ConfirmDialogService} from 'core-components/modals/confirm-dialog/confirm-dialog.service';
import {Drake} from 'dragula';

import {randomString} from 'core-app/helpers/random-string';
import {GonService} from "core-app/modules/common/gon/gon.service";

export type TypeGroupType = 'attribute'|'query';

export interface TypeFormAttribute {
  key:string;
  translation:string;
  is_cf:boolean;
}

export interface TypeGroup {
  id:string|null;
  key:string;
  originalKey:string;
  translated_key:string;
  name:string;
  attributes:TypeFormAttribute[];
  query?:any;
  type:TypeGroupType;
}

@Component({
  selector: 'admin-type-form-configuration',
  templateUrl: './type-form-configuration.html',
  providers: [
    TypeBannerService,
  ]
})
export class TypeFormConfigurationComponent implements OnInit {

  public text = {
    drag_to_activate: this.I18n.t('js.admin.type_form.drag_to_activate'),
    reset: this.I18n.t('js.admin.type_form.reset'),
    label_group: this.I18n.t('js.label_group'),
    label_inactive: this.I18n.t('js.admin.type_form.inactive'),
    custom_field: this.I18n.t('js.admin.type_form.custom_field'),
    add_group: this.I18n.t('js.admin.type_form.add_group'),
    add_table: this.I18n.t('js.admin.type_form.add_table'),
  };

  private autoscroll:any;
  private element:HTMLElement;
  private form:JQuery;

  public groups:TypeGroup[] = [];
  public inactives:TypeFormAttribute[] = [];

  private attributeDrake:Drake;
  private groupsDrake:Drake;

  private no_filter_query = this.Gon.get('no_filter_query');

  constructor(private elementRef:ElementRef,
              private I18n:I18nService,
              private Gon:GonService,
              private dragula:DragulaService,
              private confirmDialog:ConfirmDialogService,
              private notificationsService:NotificationsService,
              private externalRelationQuery:ExternalRelationQueryConfigurationService) {
  }

  ngOnInit():void {
    // Hook on form submit
    this.element = this.elementRef.nativeElement;
    this.form = jQuery(this.element).closest('form');
    this.form.on('submit.typeformupdater', () => {
      return !this.updateHiddenFields();
    });

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

  public deactivateAttribute($event:any) {
    jQuery($event.target)
      .parents('.type-form-conf-attribute')
      .appendTo('#type-form-conf-inactive-group .attributes');
    this.updateHiddenFields();
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
      group.query,
      (queryProps:any) => group.query = queryProps,
      disabledTabs
    );
  }

  public deleteGroup($event:any) {
    let group:JQuery = jQuery($event.target).parents('.type-form-conf-group');
    let attributes:JQuery = jQuery('.attributes', group).children();
    let inactiveAttributes:JQuery = jQuery('#type-form-conf-inactive-group .attributes');

    inactiveAttributes.prepend(attributes);

    group.remove();
    this.updateHiddenFields();
    return group;
  }

  public updateHiddenFields():boolean {
    let groups:HTMLElement[] = jQuery('.type-form-conf-group').not('#type-form-conf-group-template').toArray();
    let seenGroupNames:{ [name:string]:boolean } = {};
    let newAttrGroups:Array<Array<(string|Array<string>|boolean)>> = [];
    let inputAttributeGroups:JQuery;
    let hasError = false;

    // Clean up previous error states
    this.notificationsService.clear();

    // Extract new grouping from DOM structure, starting
    // with the active groups.
    groups.forEach((groupEl:HTMLElement) => {
      let group:JQuery = jQuery(groupEl);
      let groupKey:string = group.attr('data-key') as string;
      let keyIsSymbol:boolean = JSON.parse(group.attr('data-key-is-symbol') as string);
      let attrKeys:string[] = [];

      jQuery(group).removeClass('-error');
      if (groupKey == null || groupKey.length === 0) {
        // Do not save groups without a name.
        return;
      }

      if (seenGroupNames[groupKey.toLowerCase()]) {
        this.notificationsService.addError(
          I18n.t('js.types.attribute_groups.error_duplicate_group_name', {group: groupKey})
        );
        group.addClass('-error');
        hasError = true;
        return;
      }

      seenGroupNames[groupKey.toLowerCase()] = true;

      // For query groups, serialize the changed query, if any
      if (group.hasClass('type-form-query-group')) {
        const originator = group.find('.type-form-query');
        const queryProps = this.extractQuery(originator);

        newAttrGroups.push([groupKey, queryProps]);
        return;
      }


      // For attribute groups, extract the attributes
      group.find('.type-form-conf-attribute').each((i, attribute) => {
        let attr:JQuery = jQuery(attribute);
        let key:string = attr.attr('data-key') as string;
        attrKeys.push(key);
      });

      newAttrGroups.push([groupKey, attrKeys, keyIsSymbol]);
    });

    // Finally update hidden input fields
    inputAttributeGroups = jQuery('input#type_attribute_groups').first();

    inputAttributeGroups.val(JSON.stringify(newAttrGroups));

    return hasError;
  }

  public extractQuery(originator:JQuery) {
    // When the query has never been edited, the query props are stringified in the query dataset
    let persistentQuery = originator.data('query');
    // When the user edited the query at least once, the up-to-date query is persisted in queryProps dataset
    let currentQuery = originator.data('queryProps');

    return currentQuery || persistentQuery || undefined;
  }

  public createGroup(type:TypeGroupType, groupName:string = '') {
    let draggableGroups:JQuery = jQuery('#draggable-groups');
    let randomId:string = randomString(8);

    let group:TypeGroup = {
      type: type,
      name: groupName,
      id: null,
      key: randomId,
      originalKey: randomId
    };

    this.groups.unshift(group);
    return group;
  }

  public resetToDefault($event:JQuery.Event):boolean {
    this.confirmDialog
      .confirm({
        text: {
          title: this.I18n.t('js.types.attribute_groups.reset_title'),
          text: this.I18n.t('js.types.attribute_groups.confirm_reset'),
          button_continue: this.I18n.t('js.label_reset')
        }
      }).then(() => {
      this.form.find('input#type_attribute_groups').val(JSON.stringify([]));

      // Disable our form handler that updates the attribute groups
      this.form.off('submit.typeformupdater');
      this.form.trigger('submit');
    });

    $event.preventDefault();
    return false;
  }
}
