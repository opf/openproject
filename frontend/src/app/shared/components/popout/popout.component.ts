import {
  Component,
  HostBinding,
} from '@angular/core';

@Component({
  selector: 'op-dropout',
  templateUrl: './dropout.component.html',
})
export class OpDropoutComponent {
  @HostBinding('class.op-dropout') className = true;

  @HostBinding('class.op-dropout_opened') get openedClassName() {
    return this.opened;
  }

  public opened = false;

  constructor() {}
}
