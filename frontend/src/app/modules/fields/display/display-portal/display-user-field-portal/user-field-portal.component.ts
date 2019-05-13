import {Component, ElementRef, Injector, Input, OnInit} from "@angular/core";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {OpDisplayPortalLinesToken, OpDisplayPortalUserToken} from "./user-field-portal.injector";

@Component({
  selector: 'user-field-portal',
  templateUrl: './user-field-portal.component.html',
  styleUrls: ['./user-field-portal.component.sass']
})
export class UserFieldPortalComponent implements OnInit {
  @Input() userResources:UserResource[];
  @Input() multiLines:boolean;

  public users:UserResource[];
  constructor(readonly injector:Injector,
              readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    this.users = this.injector.get<UserResource[]>(OpDisplayPortalUserToken);
    this.multiLines = this.injector.get<boolean>(OpDisplayPortalLinesToken);
  }
}
