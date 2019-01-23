import {Component} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {BoardsService} from "core-app/modules/boards/board/boards.service";
import {Observable} from "rxjs";

@Component({
  selector: 'boards-module',
  templateUrl: './boards-module.component.html',
  styleUrls: ['./boards-module.component.sass']
})
export class BoardsModuleComponent {

  public boards$:Observable<Board[]> = this.Boards.loadAll('foo');

  constructor(private readonly Boards:BoardsService) {
  }

}
