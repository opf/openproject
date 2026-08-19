//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';

interface Attribute {
  url?:string;
  name?:string;
}

export class UserDisplayField extends DisplayField {
  @LazyInject() principalRenderer:PrincipalRendererService;

  public get value() {
    if (this.schema) {
      return this.typeSafeAttribute()?.name || '';
    }
    return null;
  }

  public render(element:HTMLElement, displayText:string):void {
    if (this.placeholder === displayText) {
      this.renderEmpty(element);
    } else {
      this.principalRenderer.render(
        element,
        this.typeSafeAttribute() as PrincipalLike,
        { hide: false, link: false },
        { hide: false, size: 'medium' },
        { isActivated: true, url: this.typeSafeAttribute()?.url || '' },
      );
    }
  }

  private typeSafeAttribute():Attribute {
    return this.attribute as Attribute;
  }
}
