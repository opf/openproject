import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {groupName} from './grouped-rows-helpers';
import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';
import {rowGroupClassName} from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export function groupClassNameFor(group:GroupObject) {
  return `group-${group.identifier}`;
}

export class GroupHeaderBuilder {

  @InjectField() public I18n:I18nService;
  public text:{ collapse:string, expand:string };

  constructor(public readonly injector:Injector) {
    this.text = {
      collapse: this.I18n.t('js.label_collapse'),
      expand: this.I18n.t('js.label_expand'),
    };
  }

  public buildGroupRow(group:GroupObject, colspan:number) {
    let row = document.createElement('tr');
    let togglerIconClass, text;

    if (group.collapsed) {
      text = this.text.expand;
      togglerIconClass = 'icon-plus';
    } else {
      text = this.text.collapse;
      togglerIconClass = 'icon-minus2';
    }

    row.classList.add(rowGroupClassName, groupClassNameFor(group));
    row.id = `wp-table-rowgroup-${group.index}`;
    row.dataset['groupIndex'] = (group.index).toString();
    row.dataset['groupIdentifier'] = group.identifier;
    row.innerHTML = `
      <td colspan="${colspan}" class="-no-highlighting">
        <div class="expander icon-context ${togglerIconClass}">
          <span class="hidden-for-sighted">${_.escape(text)}</span>
        </div>
        <div class="group--value">
          ${_.escape(groupName(group))}
          <span class="count">
            (${group.count})
          </span>
        </div>
      </td>
    `;

    return row;
  }
}
