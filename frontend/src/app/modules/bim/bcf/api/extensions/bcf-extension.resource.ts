import {jsonArrayMember, jsonObject} from "typedjson";

@jsonObject
export class BcfExtensionResource {

  @jsonArrayMember(String)
  topic_actions:string[];

  @jsonArrayMember(String)
  project_actions:string[];

  @jsonArrayMember(String)
  comment_actions:string[];
}
