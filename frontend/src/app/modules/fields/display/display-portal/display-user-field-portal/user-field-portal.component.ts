import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input
} from "@angular/core";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {OpDisplayPortalLinesToken, OpDisplayPortalUserToken} from "./user-field-portal.injector";

@Component({
  selector: 'user-field-portal',
  templateUrl: './user-field-portal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./user-field-portal.component.sass']
})
export class UserFieldPortalComponent implements AfterViewInit {
  @Input() userResources:UserResource[];
  @Input() multiLines:boolean;

  public users:UserResource[];

  constructor(readonly injector:Injector,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef) {
    this.users = this.injector.get<UserResource[]>(OpDisplayPortalUserToken);
    this.multiLines = this.injector.get<boolean>(OpDisplayPortalLinesToken);
  }

  ngAfterViewInit():void {
    // The lifecycle of this portal is controlled by edit fields
    // It will never be change-detectet
    this.cdRef.detach();
  }
}
