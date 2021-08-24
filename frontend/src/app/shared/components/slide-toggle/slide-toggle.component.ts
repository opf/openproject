// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnChanges,
  OnInit,
  Output,
  SimpleChanges,
} from '@angular/core';

export const slideToggleSelector = 'slide-toggle';

@Component({
  templateUrl: './slide-toggle.component.html',
  selector: slideToggleSelector,
  styleUrls: ['./slide-toggle.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})

export class SlideToggleComponent implements OnInit, OnChanges {
  @Input() containerId:string;

  @Input() containerClasses:string;

  @Input() inputId:string;

  @Input() inputName:string;

  @Input() active:boolean;

  @Output() valueChanged = new EventEmitter();

  constructor(private elementRef:ElementRef,
    private cdRef:ChangeDetectorRef) {
  }

  ngOnChanges(changes:SimpleChanges) {
    console.warn(JSON.stringify(changes));
  }

  ngOnInit() {
    const { dataset } = this.elementRef.nativeElement;

    // Allow taking over values from dataset (Rails)
    if (dataset.inputName) {
      this.containerId = dataset.containerId;
      this.containerClasses = dataset.containerClasses;
      this.inputId = dataset.inputId;
      this.inputName = dataset.inputName;
      this.active = dataset.active.toString() === 'true';
    }
  }

  public onValueChanged(val:any) {
    this.active = val;
    this.valueChanged.emit(val);
    this.cdRef.detectChanges();
  }
}
