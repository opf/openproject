import { Injectable } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ColorsService } from 'core-app/shared/components/colors/colors.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { IPrincipal } from 'core-app/core/state/principals/principal.model';
import { PrincipalLike } from './principal-types';
import {
  PrincipalType,
  hrefFromPrincipal,
  typeFromHref,
} from './principal-helper';

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
    private apiV3Service:ApiV3Service,
    private colors:ColorsService) {

  }

  renderMultiple(
    container:HTMLElement,
    users:PrincipalLike[]|IPrincipal[],
    name:NameOptions = { hide: false, link: false },
    avatar:AvatarOptions = { hide: false, size: 'default' },
    multiLine = false,
  ):void {
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
    principal:PrincipalLike|IPrincipal,
    name:NameOptions = { hide: false, link: true },
    avatar:AvatarOptions = { hide: false, size: 'default' },
  ):void {
    container.classList.add('op-principal');
    const type = typeFromHref(hrefFromPrincipal(principal)) as PrincipalType;

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
    principal:PrincipalLike|IPrincipal,
    options:AvatarOptions,
    type:PrincipalType,
  ) {
    const userInitials = this.getInitials(principal.name);
    const colorCode = this.colors.toHsl(principal.name);

    const fallback = document.createElement('div');
    fallback.classList.add('op-principal--avatar');
    fallback.classList.add('op-avatar');
    fallback.classList.add(`op-avatar_${options.size}`);
    fallback.classList.add(`op-avatar_${type.replace('_', '-')}`);
    fallback.classList.add('op-avatar--fallback');
    fallback.title = principal.name;
    fallback.textContent = userInitials;

    if (type === 'placeholder_user') {
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

  private renderUserAvatar(principal:PrincipalLike|IPrincipal, fallback:HTMLElement, options:AvatarOptions):void {
    const url = this.userAvatarUrl(principal);

    if (!url) {
      return;
    }

    const image = new Image();
    image.classList.add('op-avatar');
    image.classList.add(`op-avatar_${options.size}`);
    image.src = url;
    image.title = principal.name;
    image.alt = principal.name;
    image.onload = () => {
      fallback.replaceWith(image);
      // eslint-disable-next-line no-param-reassign
      (fallback as unknown) = undefined;
    };
  }

  private userAvatarUrl(principal:PrincipalLike|IPrincipal):string|null {
    const id = principal.id || idFromLink(hrefFromPrincipal(principal));
    return id ? this.apiV3Service.users.id(id).avatar.toString() : null;
  }

  private renderName(principal:PrincipalLike|IPrincipal, type:PrincipalType, asLink = true) {
    if (asLink) {
      const link = document.createElement('a');
      link.textContent = principal.name;
      link.href = this.principalURL(principal, type);
      link.target = '_blank';
      link.classList.add('op-principal--name');

      return link;
    }

    const span = document.createElement('span');
    span.textContent = principal.name;
    span.classList.add('op-principal--name');
    return span;
  }

  private principalURL(principal:PrincipalLike|IPrincipal, type:PrincipalType):string {
    const href = hrefFromPrincipal(principal);
    const id = principal.id || (href ? idFromLink(href) : '');

    switch (type) {
      case 'group':
        return this.pathHelper.groupPath(id);
      case 'placeholder_user':
        return this.pathHelper.placeholderUserPath(id);
      case 'user':
        return this.pathHelper.userPath(id);
      default:
        throw new Error('Invalid principal type provided');
    }
  }

  private getInitials(name:string):string {
    const characters = [...name];
    const lastSpace = name.lastIndexOf(' ');
    const first = characters[0]?.toUpperCase();
    const last = name[lastSpace + 1]?.toUpperCase();

    return [first, last].join('');
  }
}
