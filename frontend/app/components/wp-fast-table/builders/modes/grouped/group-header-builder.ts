import {$injectFields} from '../../../../angular/angular-injector-bridge.functions';
import {GroupObject} from '../../../../api/api-v3/hal-resources/wp-collection-resource.service';
import {groupName} from './grouped-rows-helpers';

export const rowGroupClassName = 'wp-table--group-header';

export function groupClassNameFor(group:GroupObject) {
  return `group-${group.identifier}`;
}

export class GroupHeaderBuilder {
  public I18n:op.I18n;
  public text:{ collapse:string, expand:string };

  constructor() {
    $injectFields(this, 'I18n');

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
    row.dataset['groupIndex'] = (group.index as number).toString();
    row.dataset['groupIdentifier'] = group.identifier as string;
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
