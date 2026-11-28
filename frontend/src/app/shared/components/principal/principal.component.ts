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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectorRef, Component, ElementRef, ViewEncapsulation, afterRenderEffect, inject, input, untracked } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { booleanAttributeOr, jsonAttribute, optionalStringAttribute, stringAttribute } from 'core-app/shared/helpers/angular/attribute-inputs';
import { AvatarOptions, AvatarSize, HoverCardOptions, isAvatarSize, NameOptions, PrincipalRendererService } from './principal-renderer.service';
import { PrincipalLike } from './principal-types';
import { PrincipalType } from 'core-app/shared/components/principal/principal-helper';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';

export const principalSelector = 'op-principal';

export interface PrincipalInput {
  type:PrincipalType;
  id:string;
}

@Component({
  template: '',
  selector: principalSelector,
  styleUrls: ['./principal.component.sass'],
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class OpPrincipalComponent {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly PathHelper = inject(PathHelperService);
  readonly principalRenderer = inject(PrincipalRendererService);
  readonly principalResourceService = inject(PrincipalsResourceService);
  readonly I18n = inject(I18nService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly timezoneService = inject(TimezoneService);
  readonly cdRef = inject(ChangeDetectorRef);

  readonly principal = input<PrincipalLike|null, PrincipalLike|string|null|undefined>(null, { transform: jsonAttribute<PrincipalLike|null>(null) });

  readonly hideAvatar = input(false, { transform: booleanAttributeOr(false) });

  readonly avatarImageAltText = input<string|undefined, string|null|undefined>(undefined, { transform: optionalStringAttribute() });

  readonly avatarImageUrl = input<string|undefined, string|null|undefined>(undefined, { transform: optionalStringAttribute() });

  readonly avatarFallbackImageUrl = input<string|undefined, string|null|undefined>(undefined, { transform: optionalStringAttribute() });

  readonly hideName = input(false, { transform: booleanAttributeOr(false) });

  readonly nameClasses = input('', { transform: stringAttribute('') });

  readonly link = input(true, { transform: booleanAttributeOr(true) });

  readonly size = input<AvatarSize, string|null|undefined>('default', {
    transform: (value) => (isAvatarSize(value) ? value : 'default'),
  });

  readonly avatarClasses = input('', { transform: stringAttribute('') });

  readonly hoverCard = input(true, { transform: booleanAttributeOr(true) });

  readonly hoverCardUrl = input('', { transform: stringAttribute('') });

  readonly nameTitle = input('', { transform: stringAttribute('') });

  public constructor() {
    afterRenderEffect({
      write: () => {
        const principal = this.principal();
        const name:NameOptions = {
          hide: this.hideName(),
          link: this.link(),
          classes: this.nameClasses(),
        };
        const avatarOptions:AvatarOptions = {
          hide: this.hideAvatar(),
          size: this.size(),
          imageAltText: this.avatarImageAltText(),
          imageUrl: this.avatarImageUrl(),
          fallbackImageUrl: this.avatarFallbackImageUrl(),
        };
        const hoverCardOptions:HoverCardOptions = {
          isActivated: this.hoverCard(),
          url: this.hoverCardUrl(),
        };
        const nameTitle = this.nameTitle();

        untracked(() => {
          const host = this.elementRef.nativeElement;
          host.replaceChildren();
          if (!principal?.name) return;

          this.principalRenderer.render(
            host,
            principal,
            name,
            avatarOptions,
            hoverCardOptions,
            nameTitle === '' ? null : nameTitle,
          );
        });
      },
    });
  }
}
