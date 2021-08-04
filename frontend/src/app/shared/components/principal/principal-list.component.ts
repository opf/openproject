import {
  ChangeDetectionStrategy,
  Component,
  Input,
} from '@angular/core';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';

@Component({
  selector: 'op-principal-list',
  templateUrl: './principal-list.component.html',
  styleUrls: [],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'op-principal-list',
  },
})
export class OpPrincipalListComponent {
  @Input() principals:PrincipalLike[];

  constructor() {}
}
