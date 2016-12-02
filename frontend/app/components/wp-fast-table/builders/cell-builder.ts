import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from './../../wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageDisplayFieldService} from './../../wp-display/wp-display-field/wp-display-field.service';
export const cellClassName = 'wp-table--cell-span';
export const cellEmptyPlaceholder = '-';

export class CellBuilder {

  constructor(private wpDisplayField:WorkPackageDisplayFieldService) {
  }

  public build(workPackage:WorkPackageResource, name:string) {
    let fieldSchema = workPackage.schema[name];

    let td = document.createElement('td');
    let span = document.createElement('span');
    span.classList.add(cellClassName, name);
    const field = <DisplayField> this.wpDisplayField.getField(workPackage, name, fieldSchema);

    let text;

    if (fieldSchema.writable) {
      span.classList.add('-editable');
    }

    if (fieldSchema.required) {
      span.classList.add('-required');
    }

    if (field.isEmpty()) {
      span.classList.add('-placeholder');
      text = cellEmptyPlaceholder;
    } else {
      td.setAttribute("aria-label", field.label + " " + text);
      text = field.valueString;
    }

    field.render(span, text);
    td.appendChild(span);

    return td;
  }

}