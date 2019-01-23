import {Injectable} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {Observable, of} from "rxjs";

@Injectable()
export class BoardsService {

  private boards:Board[] = [
    new Board(1, 'Other Board', [5, 7, 8]),
    new Board(1, 'My Board', [8, 5])
  ];

  public loadAll(projectIdentifier:string):Observable<Board[]> {
    return of(this.boards);
  }

  public load(id:number):Observable<Board|undefined> {
    return of(this.boards.find(b => b.id === id));
  }
}
