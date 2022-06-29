import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'storybook-button',
  template: `<button
    type="button"
    [ngClass]="classes"
  >
    {{ label }}
    <span
      class="spot-icon spot-icon_bell"
      *ngIf="showIcon"
    ></span>
  </button>`,
  styleUrls: ['./button.css'],
})
export default class ButtonComponent {
  /**
   * Is this the principal call to action on the page?
   */
  @Input()
  disabled = false;

  /**
   * What background color to use
   */
  @Input()
  outlined = false;

  /**
   * What background color to use
   */
  @Input()
  showIcon = false;

  /**
   * How large should the button be?
   */
  @Input()
  type: 'default' | 'main' | 'accent' | 'danger' = 'default';

  /**
   * Button contents
   *
   * @required
   */
  @Input()
  label = 'Button';

  /**
   * Optional click handler
   */
  @Output()
  onClick = new EventEmitter<Event>();

  public get classes(): string[] {
    return [
      'spot-button',
      ...(this.outlined ? ['spot-button_outlined'] : []),       
      ...(this.type !== 'default' ? [`spot-button_${this.type}`] : []),       
    ];
  }
}
