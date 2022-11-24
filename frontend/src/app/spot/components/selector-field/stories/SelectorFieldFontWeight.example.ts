import { ChangeDetectionStrategy, Component } from '@angular/core';
import { SpotCheckboxState } from 'core-app/spot/components/checkbox/checkbox.component';

@Component({
  templateUrl: './SelectorFieldFontWeight.example.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SbSelectorFieldFontWeightExample {
  public mixed:SpotCheckboxState = null;
}
