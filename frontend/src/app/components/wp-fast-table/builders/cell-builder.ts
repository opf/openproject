import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {
  DisplayFieldRenderer,
  editFieldContainerClass
} from "core-app/modules/fields/display/display-field-renderer";
import {Injector} from '@angular/core';
import {QueryColumn} from "core-components/wp-query/query-column";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
export const tdClassName = 'wp-table--cell-td';
export const editCellContainer = 'wp-table--cell-container';

export class CellBuilder {

  @InjectField(SchemaCacheService) schemaCache:SchemaCacheService;

  public fieldRenderer = new DisplayFieldRenderer(this.injector, 'table');

  constructor(public injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    const attribute = column.id;
    td.classList.add(tdClassName, attribute);

    if (attribute === 'subject') {
      td.classList.add('-max');
    }

    const schema = this.schemaCache.of(workPackage).ofProperty(attribute);
    if (schema && schema.type === 'User') {
      td.classList.add('-contains-avatar');
    }

    const container = document.createElement('span');
    container.classList.add(editCellContainer, editFieldContainerClass, attribute);
    const displayElement = this.fieldRenderer.render(workPackage, attribute, null);

    container.appendChild(displayElement);
    td.appendChild(container);

    return td;
  }

  public refresh(container:HTMLElement, workPackage:WorkPackageResource, attribute:string) {
    const displayElement = this.fieldRenderer.render(workPackage, attribute, null);

    container.innerHTML = '';
    container.appendChild(displayElement);
  }
}
