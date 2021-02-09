import { Type } from '@angular/core';
import { TabComponent } from './tab.component';

export class Tab {
  constructor(
    public component: Type<TabComponent>,
    public displayName: String,
    public identifier: String,
  ) {}
}
