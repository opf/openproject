import {ChangeDetectionStrategy, Component, ElementRef, Injector, Input} from "@angular/core";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {OpDisplayPortalLinesToken, OpDisplayPortalUserToken} from "./user-field-portal.injector";

@Component({
  selector: 'user-field-portal',
  templateUrl: './user-field-portal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./user-field-portal.component.sass']
})
export class UserFieldPortalComponent {
  @Input() userResources:UserResource[];
  @Input() multiLines:boolean;

  public users:UserResource[];

  constructor(readonly injector:Injector,
              readonly elementRef:ElementRef) {
    this.users = this.injector.get<UserResource[]>(OpDisplayPortalUserToken);
    this.multiLines = this.injector.get<boolean>(OpDisplayPortalLinesToken);
  }
}
