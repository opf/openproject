import {Component} from "@angular/core";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";

@Component({
  selector: 'boards-entry',
  template: '<ui-view></ui-view>',
  providers: [
    BoardCacheService
  ]
})
export class BoardsRootComponent {
}
