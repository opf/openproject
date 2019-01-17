import {Component} from "@angular/core";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'boards-module',
  templateUrl: './boards-module.component.html'
})
export class BoardsModuleComponent {
}

DynamicBootstrapper.register({
  selector: 'boards-module',
  cls: BoardsModuleComponent
});
