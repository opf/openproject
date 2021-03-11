import {Injectable} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ColorsService} from "core-app/modules/common/colors/colors.service";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {PrincipalHelper} from "core-app/modules/common/principal/principal-helper";
import PrincipalType = PrincipalHelper.PrincipalType;

export interface PrincipalLike {
  id:string;
  name:string;
  href:string;
}
export interface AvatarOptions {
  classes:string;
}

@Injectable({ providedIn: 'root' })
export class PrincipalRendererService {

  constructor(private pathHelper:PathHelperService,
              private apiV3Service:APIV3Service,
              private colors:ColorsService) {

  }

  renderMultiple(container:HTMLElement,
                 users:PrincipalLike[],
                 renderName:boolean = true,
                 multiLine:boolean = false) {

    const span = document.createElement('span');


    for (let i = 0; i < users.length; i++) {
      const avatar = document.createElement('span');
      if (multiLine) {
        avatar.classList.add('user-avatar--multi-line');
      }

      this.render(avatar, users[i], renderName);

      if (!multiLine && i < users.length - 1) {
        const sep = document.createElement('span');
        sep.textContent = ', ';
        avatar.appendChild(sep);
      }

      span.appendChild(avatar);
    }

    container.appendChild(span);
  }

  render(container:HTMLElement,
         principal:PrincipalLike,
         name:boolean = true,
         avatar:false|AvatarOptions = { classes: 'avatar-medium' }):void {

    const type = PrincipalHelper.typeFromHref(principal.href)!;

    if (avatar) {
      const el = this.renderAvatar(principal, avatar, type);
      container.appendChild(el);
    }

    if (name) {
      const el = this.renderName(principal, type);
      container.appendChild(el);
    }
  }

  private renderAvatar(principal:PrincipalLike, avatar:AvatarOptions, type:PrincipalType) {
    const userInitials = this.getInitials(principal.name);
    const colorCode = this.colors.toHsl(principal.name);

    let fallback = document.createElement('div');
    fallback.className = avatar.classes;
    fallback.classList.add('avatar-default');
    fallback.textContent = userInitials;
    fallback.style.background = colorCode;

    // Image avatars are only supported for users
    if (type === 'user') {
      this.renderUserAvatar(principal, fallback, avatar);
    }

    return fallback;
  }

  private renderUserAvatar(principal:PrincipalLike, fallback:HTMLElement, avatar:AvatarOptions) {
    const image = new Image();
    image.className = avatar.classes;
    image.classList.add('avatar--fallback');
    image.src = this.apiV3Service.users.id(principal.id).avatar.toString();
    image.title = principal.name;
    image.alt = principal.name;
    image.onload = function () {
      fallback.replaceWith(image);
      (fallback as any) = undefined;
    };
  }

  private renderName(principal:PrincipalLike, type:PrincipalType) {
    const link = document.createElement('a');
    link.textContent = principal.name;
    link.href = this.principalURL(principal, type);
    link.target = '_blank';

    return link;
  }

  private principalURL(principal:PrincipalLike, type:PrincipalType) {
    switch (type) {
      case 'group':
        return this.pathHelper.groupPath(principal.id);
      case 'placeholder_user':
        return this.pathHelper.placeholderUserPath(principal.id);
      case 'user':
        return this.pathHelper.userPath(principal.id);
    }
  }

  private getInitials(name:string) {
    let characters = [...name];
    let lastSpace = name.lastIndexOf(' ');
    let first = characters[0]?.toUpperCase();
    let last = name[lastSpace + 1]?.toUpperCase();

    return [first, last].join("");
  }
}