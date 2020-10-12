import {jsonMember, jsonObject} from "typedjson";

@jsonObject
export class BcfProjectResource {

  @jsonMember
  project_id:number;

  @jsonMember
  name:string;
}
