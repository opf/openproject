import {
  ChangeDetectionStrategy,
  Component,
  Input,
  HostBinding,
} from '@angular/core';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';

@Component({
  selector: 'op-principal-list',
  templateUrl: './principal-list.component.html',
  styleUrls: [],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpPrincipalListComponent {
  @HostBinding('class.op-principal-list') className = true;

  @Input() principals:PrincipalLike[];
}
