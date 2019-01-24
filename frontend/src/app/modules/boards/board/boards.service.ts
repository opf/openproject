import {Injectable} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {Observable, of} from "rxjs";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";

@Injectable()
export class BoardsService {

  private boards:Board[] = [
    new Board(1, 'Other Board', [5, 7, 8]),
    new Board(2, 'My Board', [8, 5])
  ];

  constructor(private readonly BoardsList:BoardListsService) {
  }


  public loadAll(projectIdentifier:string):Observable<Board[]> {
    return of(this.boards);
  }

  public load(id:number):Observable<Board|undefined> {
    return of(this.boards.find(b => b.id === id));
  }

  public create(name:string = 'New board'):Promise<Board> {
    return this.BoardsList
      .create()
      .then(query => {
        const id:number = _.max(this.boards.map(b => b.id)) || 0;
        const board = new Board(id + 1, name, [query]);
        this.boards.push(board);

        return board;
      });
  }

  update(board:Board) {
    _.remove(this.boards, b => b.id === board.id);
    this.boards.push(board);
  }
}
