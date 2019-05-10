import {ChangeDetectorRef, Component, ElementRef, Injector, Input, OnInit} from "@angular/core";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {OpDisplayPortalUserToken} from "./user-field-portal.injector";

@Component({
  selector: 'user-field-portal',
  templateUrl: './user-field-portal.component.html'
})
export class UserFieldPortalComponent implements OnInit {
  @Input() userResource:UserResource;

  public user:UserResource;
  public userUrl:string;
  constructor(readonly injector:Injector,
              readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    this.user = this.injector.get<UserResource>(OpDisplayPortalUserToken);
    this.userUrl = this.user.href || '';
  }
}
