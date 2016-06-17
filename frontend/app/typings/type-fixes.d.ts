declare namespace typeFixes {
  
  interface ArrayFix {
    length: number;
    filter(callback: Function, thisArg?: any);
    find(callback: Function, thisArg?: any);
    findIndex(callback: Function, thisArg?: any);
    forEach(callback: Function);
    indexOf(searchElement: any, fromIndex?: any);
    push(elements: any);
    sort(compareFunction: Function);
  }

}
