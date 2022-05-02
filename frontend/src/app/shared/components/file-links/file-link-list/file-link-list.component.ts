// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy, Component, Input, OnInit,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Observable, of } from 'rxjs';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';

@Component({
  selector: 'op-file-link-list',
  templateUrl: './file-link-list.html',
  styleUrls: ['./file-link-list.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public resource:HalResource;

  $fileLinks:Observable<IFileLink[]>;

  ngOnInit():void {
    this.$fileLinks = of([
      {
        id: 1,
        originData: {
          name: 'awesome.png',
          lastModifiedAt: '2022-04-01T12:00Z',
          lastModifiedByName: 'Anakin Skywalker',
        },
      },
      {
        id: 2,
        originData: {
          name: 'logo.png',
          lastModifiedAt: '2022-04-01T12:00Z',
          lastModifiedByName: 'Leia Organa',
        },
      },
    ]);
  }
}
