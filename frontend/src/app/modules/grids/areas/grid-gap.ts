import { GridArea } from "core-app/modules/grids/areas/grid-area";

export class GridGap extends GridArea {
  private type:'row'|'column';

  constructor(startRow:number, endRow:number, startColumn:number, endColumn:number, type:'row'|'column') {
    super(startRow, endRow, startColumn, endColumn);

    this.type = type;
  }

  public get gridStartRow() {
    if (this.isRow) {
      return this.startRow * 2 - 1;
    } else {
      return this.startRow * 2;
    }
  }

  public get gridEndRow() {
    if (this.isRow) {
      return this.endRow * 2 - 2;
    } else {
      return this.endRow * 2 - 1;
    }
  }

  public get gridStartColumn() {
    if (this.isRow) {
      return this.startColumn * 2;
    } else {
      return this.startColumn * 2 - 1;
    }
  }

  public get gridEndColumn() {
    if (this.isRow) {
      return this.endColumn * 2 - 1;
    } else {
      return this.endColumn * 2 - 2;
    }
  }

  public get isRow() {
    return this.type === 'row';
  }

  public get isColumn() {
    return this.type === 'column';
  }
}
