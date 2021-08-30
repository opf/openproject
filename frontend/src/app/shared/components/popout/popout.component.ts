import {
  Component,
  HostBinding,
  Input,
} from '@angular/core';

export enum OpPopoutAlignment {
  Down = 'down',
  Up = 'up',
}

@Component({
  selector: 'op-popout',
  templateUrl: './popout.component.html',
})
export class OpPopoutComponent {
  @HostBinding('class.op-popout') className = true;

  @HostBinding('class.op-popout_opened') get openedClassName() {
    return this.opened;
  }

  @HostBinding('class') get alignmentClassName() {
    return { [`op-popout_align-${this.alignment}`]: true };
  }

  @Input() alignment: OpPopoutAlignment = OpPopoutAlignment.Down;

  public opened = false;
}
