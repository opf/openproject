import {IOPFormlyFieldSettings} from "core-app/modules/common/dynamic-forms/typings";
import {FormlyFieldConfig} from "@ngx-formly/core";

export namespace ProjectFormAttributeGroups {

  /**
   * Create a collapsible formly fieldset for the given fields
   * @param {IOPFormlyFieldSettings[]} fields Fields to include in the fieldset
   * @param {string} label Label of the fieldset
   */
  export function collapsibleFieldset(
    fields:IOPFormlyFieldSettings[],
    label:string,
  ):IOPFormlyFieldSettings {
    return {
      fieldGroup: fields,
      fieldGroupClassName: "op-form--field-group",
      templateOptions: {
        label: label,
        isFieldGroup: true,
        collapsibleFieldGroups: true,
        collapsibleFieldGroupsCollapsed: true,
      },
      type: "formly-group" as "formly-group",
      wrappers: ["op-dynamic-field-group-wrapper"],
      expressionProperties: {
        'templateOptions.collapsibleFieldGroupsCollapsed': (model:unknown, formState:unknown, field:FormlyFieldConfig) => {
          // Uncollapse field groups when the form has errors and has been submitted
          if (
            field.type !== 'formly-group' ||
            !field.templateOptions?.collapsibleFieldGroups ||
            !field.templateOptions?.collapsibleFieldGroupsCollapsed
          ) {
            return;
          } else {
            return !(
              field.fieldGroup?.some(groupField =>
                groupField?.formControl?.errors &&
                !groupField.hide &&
                field.options?.parentForm?.submitted
              ));
          }
        },
      }
    };
  }
}