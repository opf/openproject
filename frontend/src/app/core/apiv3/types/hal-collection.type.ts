export interface IHALGrouping {
  value:string;
  count:number;
  _links:{
    valueLink:{
      href:string;
    }[];
  };
}

export interface IHALCollection<T> {
  _type:'Collection';
  count:number;
  total:number;
  pageSize:number;
  offset:number;
  groups?:IHALGrouping[];
  _embedded:{
    elements:T[];
  }
}
