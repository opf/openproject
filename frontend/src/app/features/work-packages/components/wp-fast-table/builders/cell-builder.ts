import {
  WorkPackageResource,
} from 'core-app/features/hal/resources/work-package-resource';
import {
  DisplayFieldRenderer,
  editFieldContainerClass,
} from 'core-app/shared/components/fields/display/display-field-renderer';
import { Injector } from '@angular/core';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { IWorkPackageTimestamp } from 'core-app/features/hal/resources/work-package-timestamp-resource';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';

export const tdClassName = 'wp-table--cell-td';
export const editCellContainer = 'wp-table--cell-container';

export class CellBuilder {
  @InjectField(SchemaCacheService) schemaCache:SchemaCacheService;

  @InjectField(WorkPackageViewBaselineService) wpTableBaseline:WorkPackageViewBaselineService;

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

    if (['startDate', 'dueDate', 'duration'].includes(attribute)) {
      td.classList.add('-no-ellipsis');
    }

    if (['estimatedTime', 'remainingTime'].includes(attribute)) {
      td.classList.add('-min-200');
    }

    const schema = this.schemaCache.of(workPackage);
    const fieldSchema = schema.ofProperty(attribute);
    if (fieldSchema && fieldSchema.type === 'User') {
      td.classList.add('-contains-avatar');
    }

    const container = document.createElement('span');
    td.appendChild(container);
    this.render(container, workPackage, attribute);

    return td;
  }

  public refresh(container:HTMLElement, workPackage:WorkPackageResource, attribute:string) {
    container.innerHTML = '';
    this.render(container, workPackage, attribute);
  }

  private render(container:HTMLElement, workPackage:WorkPackageResource, attribute:string) {
    const schema = this.schemaCache.of(workPackage);
    const mappedName = schema.mappedName(attribute);
    const hasBaseline = attribute !== 'id' && this.wpTableBaseline.isChanged(workPackage, mappedName);
    container.classList.add(editCellContainer, editFieldContainerClass, attribute);

    const displayElement = this.fieldRenderer.render(workPackage, attribute, null);

    if (hasBaseline) {
      displayElement.classList.add('op-table-baseline--field', 'op-table-baseline--new-field');
      this.prependChanges(container, workPackage, mappedName);
    }

    container.appendChild(displayElement);
  }

  private prependChanges(
    container:HTMLElement,
    workPackage:WorkPackageResource,
    attribute:string,
  ):void {
    const base = (workPackage.attributesByTimestamp as IWorkPackageTimestamp[])[0];
    base.$links.schema = base.$links.schema || workPackage.$links.schema;
    const span = this.fieldRenderer.render(base, attribute, null);
    span.classList.add('op-table-baseline--field', 'op-table-baseline--old-field');
    container.classList.add('op-table-baseline--container');
    (container.parentElement as HTMLTableElement).classList.add('op-table-baseline--cell');
    container.classList.remove(editCellContainer);
    container.appendChild(span);
  }
}
