import {Component, OnDestroy, OnInit, ViewEncapsulation} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {StateService} from "@uirouter/core";
import {Observable} from "rxjs";
import {BoardsService} from "core-app/modules/boards/board/boards.service";
import {filter} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";

@Component({
  selector: 'board',
  templateUrl: './board.component.html',
  styleUrls: ['./board.component.sass'],
  encapsulation: ViewEncapsulation.None,
  providers: [
    DragAndDropService
  ]
})
export class BoardComponent implements OnInit, OnDestroy {

  public board$:Observable<Board>;

  constructor(private readonly state:StateService,
              private readonly Boards:BoardsService) {
  }

  ngOnInit():void {
    const id = this.state.params.id;
    this.board$ = this.Boards
      .load(id)
      .pipe(
        untilComponentDestroyed(this),
        filter((b) => b !== undefined)
      ) as Observable<Board>;

  }

  ngOnDestroy():void {
    // Nothing to do
  }


}
