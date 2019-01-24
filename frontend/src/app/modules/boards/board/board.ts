import {QueryResource} from "core-app/modules/hal/resources/query-resource";

export class Board {
  constructor(public readonly id:number,
              public name:string,
              public queries:(QueryResource|number)[]) {
  }
}
