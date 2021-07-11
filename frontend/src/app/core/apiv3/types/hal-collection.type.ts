export interface IHALCollection<T> {
  _type:'Collection';
  count:number;
  total:number;
  pageSize:number;
  offset:number;
  _embedded:{
    elements:T[];
  }
}
