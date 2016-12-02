import {States} from '../../states.service';
import {WorkPackageResource} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageEditForm} from '../../wp-edit-form/work-package-edit-form';
import {State} from '../../../helpers/reactive-fassade';
export class RowEditHandler {

  protected workPackage:WorkPackageResource;
  protected editState:State<WorkPackageEditForm>;

  constructor(public row:HTMLTableRowElement,
              public cell:HTMLTableCellElement,
              public evt:JQueryEventObject,
              public states: States) {

    this.workPackage =

    // Mark row as being edited
    row.classList.add('-editing');

  }
}
