import { Injectable } from "@angular/core";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { ColorsService } from "core-app/modules/common/colors/colors.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

import { PrincipalLike } from "./principal-types";
import { PrincipalHelper } from "./principal-helper";
import PrincipalType = PrincipalHelper.PrincipalType;

export type AvatarSize = 'default'|'medium'|'mini';

export interface AvatarOptions {
  hide:boolean;
  size:AvatarSize;
}

export interface NameOptions {
  hide:boolean;
  link:boolean;
}

@Injectable({ providedIn: 'root' })
export class PrincipalRendererService {

  constructor(private pathHelper:PathHelperService,
              private apiV3Service:APIV3Service,
              private colors:ColorsService) {

  }

  renderMultiple(
    container:HTMLElement,
    users:PrincipalLike[],
    name:NameOptions = { hide: false, link: false },
    avatar:AvatarOptions = { hide: false, size: 'default' },
    multiLine:boolean = false,
  ) {
    container.classList.add('op-principal');
    const list = document.createElement('span');

    for (let i = 0; i < users.length; i++) {
      const userElement = document.createElement('span');
      if (multiLine) {
        userElement.classList.add('op-principal--multi-line');
      }

      this.render(userElement, users[i], name, avatar);

      list.appendChild(userElement);

      if (!multiLine && i < users.length - 1) {
        const sep = document.createElement('span');
        sep.textContent = ', ';
        list.appendChild(sep);
      }
    }

    container.appendChild(list);
  }

  render(
    container:HTMLElement,
    principal:PrincipalLike,
    name:NameOptions = { hide: false, link: true },
    avatar:AvatarOptions = { hide: false, size: 'default' },
  ):void {
    container.classList.add('op-principal');
    const type = PrincipalHelper.typeFromHref(principal.href || '')!;

    if (!avatar.hide) {
      const el = this.renderAvatar(principal, avatar, type);
      container.appendChild(el);
    }

    if (!name.hide) {
      const el = this.renderName(principal, type, name.link);
      container.appendChild(el);
    }
  }

  private renderAvatar(
    principal:PrincipalLike,
    options:AvatarOptions,
    type:PrincipalType,
  ) {
    const userInitials = this.getInitials(principal.name);
    const colorCode = this.colors.toHsl(principal.name);

    const fallback = document.createElement('div');
    fallback.classList.add('op-avatar');
    fallback.classList.add(`op-avatar_${options.size}`);
    fallback.classList.add(`op-avatar_${type.replace('_', '-')}`);
    fallback.classList.add('op-avatar--fallback');
    fallback.textContent = userInitials;

    if (type === "placeholder_user") {
      fallback.style.color = colorCode;
      fallback.style.borderColor = colorCode;
    } else {
      fallback.style.background = colorCode;
    }

    // Image avatars are only supported for users
    if (type === 'user') {
      this.renderUserAvatar(principal, fallback, options);
    }

    return fallback;
  }

  private renderUserAvatar(principal:PrincipalLike, fallback:HTMLElement, options:AvatarOptions) {
    const image = new Image();
    image.classList.add('op-avatar');
    image.classList.add(`op-avatar_${options.size}`);
    image.src = this.apiV3Service.users.id(principal.id || '').avatar.toString();
    image.title = principal.name;
    image.alt = principal.name;
    image.onload = function () {
      fallback.replaceWith(image);
      (fallback as any) = undefined;
    };
  }

  private renderName(principal:PrincipalLike, type:PrincipalType, asLink = true) {
    if (asLink) {
      const link = document.createElement('a');
      link.textContent = principal.name;
      link.href = this.principalURL(principal, type);
      link.target = '_blank';

      return link;
    }

    const span = document.createElement('span');
    span.textContent = principal.name;
    return span;
  }

  private principalURL(principal:PrincipalLike, type:PrincipalType) {
    switch (type) {
      case 'group':
        return this.pathHelper.groupPath(principal.id || '');
      case 'placeholder_user':
        return this.pathHelper.placeholderUserPath(principal.id || '');
      case 'user':
        return this.pathHelper.userPath(principal.id || '');
    }
  }

  private getInitials(name:string) {
    const characters = [...name];
    const lastSpace = name.lastIndexOf(' ');
    const first = characters[0]?.toUpperCase();
    const last = name[lastSpace + 1]?.toUpperCase();

    return [first, last].join("");
  }
}