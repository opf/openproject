import {Injectable} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ColorsService} from "core-app/modules/common/colors/colors.service";

export interface UserLike {
  name:string;
  id:string|number|null;
}

@Injectable({ providedIn: 'root' })
export class UserAvatarRendererService {

  constructor(private pathHelper:PathHelperService,
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
    const userInitials = this.getInitials(user.name);
    const colorCode = this.colors.toHsl(user.name);

    let fallback = document.createElement('div');
    fallback.className = classes;
    fallback.classList.add('avatar-default');
    fallback.textContent = userInitials;
    fallback.style.background = colorCode;

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
    image.src = this.pathHelper.api.v3.users.id(user.id).avatar.toString();
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