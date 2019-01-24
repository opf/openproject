import {Component, OnDestroy, OnInit} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {StateService} from "@uirouter/core";
import {Observable} from "rxjs";
import {BoardsService} from "core-app/modules/boards/board/boards.service";
import {filter} from "rxjs/operators";

@Component({
  selector: 'board',
  templateUrl: './board.component.html',
  styleUrls: ['./board.component.sass'],
  providers: [
    DragAndDropService
  ]
})
export class BoardComponent implements OnInit, OnDestroy {

  public board$:Observable<Board>;

  constructor(private readonly state:StateService,
              private readonly Boards:BoardsService) {
  }

  goBack() {
    this.state.go('^');
  }

  ngOnInit():void {
    const id = this.state.params.id;
    this.board$ = this.Boards
      .load(id)
      .pipe(
        filter((b) => b !== undefined)
      ) as Observable<Board>;

  }

  ngOnDestroy():void {
    // Nothing to do
  }


}
