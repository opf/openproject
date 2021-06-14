//-- copyright
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

import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { Component, ElementRef, EventEmitter, Input, Output, ViewChild } from "@angular/core";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";



@Component({
  selector: 'wp-relations-group',
  templateUrl: './wp-relations-group.template.html'
})
export class WorkPackageRelationsGroupComponent {
  @Input() public relatedWorkPackages:WorkPackageResource[];
  @Input() public workPackage:WorkPackageResource;
  @Input() public header:string;
  @Input() public firstGroup:boolean;
  @Input() public groupByWorkPackageType:boolean;

  @Output() public onToggleGroupBy = new EventEmitter<undefined>();

  @ViewChild('wpRelationGroupByToggler') readonly toggleElement:ElementRef;

  public text = {
    groupByType: this.I18n.t('js.relation_buttons.group_by_wp_type'),
    groupByRelation: this.I18n.t('js.relation_buttons.group_by_relation_type')
  };

  constructor(
    readonly I18n:I18nService) {
  }

  public get togglerText() {
    if (this.groupByWorkPackageType) {
      return this.text.groupByRelation;
    } else {
      return this.text.groupByType;
    }
  }

  public toggleButton() {
    this.onToggleGroupBy.emit();

    setTimeout(() => {
      this.toggleElement.nativeElement.focus();
    }, 20);
  }
}
