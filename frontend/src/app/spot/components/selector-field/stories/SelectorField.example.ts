import { ChangeDetectionStrategy, Component } from '@angular/core';
import { SpotCheckboxState } from 'core-app/spot/components/checkbox/checkbox.component';

@Component({
  templateUrl: './SelectorField.example.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SbSelectorFieldExample {
  public mixed:SpotCheckboxState = null;
}
