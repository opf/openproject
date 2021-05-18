export class GridArea {
  private storedGuid:string;
  public startRow:number;
  public endRow:number;
  public startColumn:number;
  public endColumn:number;

  constructor(startRow:number, endRow:number, startColumn:number, endColumn:number) {
    this.startRow = startRow;
    this.endRow = endRow;
    this.startColumn = startColumn;
    this.endColumn = endColumn;
  }

  public get gridStartRow() {
    return this.startRow * 2;
  }

  public get gridEndRow() {
    return this.endRow * 2 - 1;
  }

  public get gridStartColumn() {
    return this.startColumn * 2;
  }

  public get gridEndColumn() {
    return this.endColumn * 2 - 1;
  }

  public get guid():string {
    if (!this.storedGuid) {
      this.storedGuid = this.newGuid();
    }

    return this.storedGuid;
  }

  private newGuid() {
    function s4() {
      return Math.floor((1 + Math.random()) * 0x10000)
        .toString(16)
        .substring(1);
    }
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
  }
}

