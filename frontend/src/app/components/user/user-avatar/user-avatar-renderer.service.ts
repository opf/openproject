import {Injectable} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ColorsService} from "core-app/modules/common/colors/colors.service";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";

export interface UserLike {
  name:string;
  id:string|number|null;
  href:string|null;
}

@Injectable({ providedIn: 'root' })
export class UserAvatarRendererService {

  constructor(private pathHelper:PathHelperService,
              private apiV3Service:APIV3Service,
              private colors:ColorsService) {

  }

  renderMultiple(container:HTMLElement,
                 users:UserLike[],
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
         user:UserLike,
         renderName:boolean = true,
         classes:string = 'avatar-medium'):void {
    const colorCode = this.colors.toHsl(user.name);

    let fallback = document.createElement('div');
    fallback.className = classes;
    fallback.textContent = this.getInitials(user.name)
    fallback.classList.add('avatar-default');
    // Todo: move this matcher to HAL ressource
    if (user.href && user.href.includes('/placeholder_users/')) {
      fallback.classList.add("-placeholder-user");
      fallback.style.color = colorCode;
      fallback.style.borderColor = colorCode;
      fallback.style.background = 'transparent';
    } else if (user.href && user.href.includes('/groups/')) {
      fallback.classList.add("-group");
      fallback.style.background = colorCode;
    } else {
      fallback.classList.add("-user");
      fallback.style.background = colorCode;
    }

    container.appendChild(fallback);

    if (renderName) {
      const name = document.createElement('span');
      name.textContent = user.name;
      container.appendChild(name);
    }

    // Avoid using the image when ID is null
    if (!user.id) {
      return;
    }

    const image = new Image();
    image.className = classes;
    image.classList.add('avatar--fallback');
    image.src = this.apiV3Service.users.id(user.id).avatar.toString();
    image.title = user.name;
    image.alt = user.name;
    image.onload = function () {
      fallback.replaceWith(image);
      (fallback as any) = undefined;
    };
  }

  private getInitials(name:string) {
    let characters = [...name];
    let lastSpace = name.lastIndexOf(' ');
    let first = characters[0]?.toUpperCase();
    let last = name[lastSpace + 1]?.toUpperCase();

    return [first, last].join("");
  }
}