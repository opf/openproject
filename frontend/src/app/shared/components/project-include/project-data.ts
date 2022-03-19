import { ID } from '@datorama/akita';

export interface IProjectData {
  id:ID;
  href:string;
  name:string;
  found:boolean;
  children:IProjectData[];
}
