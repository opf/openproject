import { jsonMember, jsonObject } from 'typedjson';

@jsonObject
export class BcfProjectResource {
  @jsonMember(Number)
  project_id:number;

  @jsonMember(String)
  name:string;
}
