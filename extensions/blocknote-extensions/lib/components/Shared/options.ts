export interface AllowedValue {
  href:string;
  label:string;
  favored?:boolean;
  ancestors?:string[];
}

export interface ListedValue extends AllowedValue {
  depth:number;
  hasChildren:boolean;
  expanded:boolean;
  position:number;
  levelSize:number;
}
