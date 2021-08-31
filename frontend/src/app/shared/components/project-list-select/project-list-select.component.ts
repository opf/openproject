import {
  Component,
  HostBinding,
} from '@angular/core';

@Component({
  selector: 'op-project-list-select',
  templateUrl: './project-list-select.component.html',
})
export class OpProjectListSelectComponent {
  @HostBinding('class.op-project-list-select') className = true;

  public clearSelection() {
  }

  public search() {
  }
}
