import { ID } from '@datorama/akita';

export interface IProjectData {
  id:ID;
  href:string;
  name:string;
  disabled:boolean;
  children:IProjectData[];
  position:number;
}
