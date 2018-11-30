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

  public moveRight() {
    this.startColumn++;
    this.endColumn++;
  }

  public moveLeft() {
    this.startColumn--;
    this.endColumn--;
  }

  public growColumn() {
    this.endColumn++;
  }

  public doesContain(otherArea:GridArea) {
    return this.isTopLeftInside(otherArea) ||
      this.isTopRightInside(otherArea) ||
      this.isBottomLeftInside(otherArea) ||
      this.isBottomRightInside(otherArea);
  }

  private isTopLeftInside(otherArea:GridArea) {
    return this.startRow <= otherArea.startRow && this.endRow > otherArea.startRow &&
      this.startColumn <= otherArea.startColumn && this.endColumn > otherArea.startColumn;
  }

  private isTopRightInside(otherArea:GridArea) {
    return this.startRow <= otherArea.startRow && this.endRow > otherArea.startRow &&
      this.startColumn < otherArea.endColumn && this.endColumn >= otherArea.endColumn;
  }

  private isBottomLeftInside(otherArea:GridArea) {
    return this.startRow <= otherArea.startRow && this.endRow > otherArea.startRow &&
      this.startColumn < otherArea.endColumn && this.endColumn >= otherArea.endColumn;
  }

  private isBottomRightInside(otherArea:GridArea) {
    return this.startRow < otherArea.endRow && this.endRow >= otherArea.endRow &&
      this.startColumn < otherArea.endColumn && this.endColumn >= otherArea.endColumn;
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

