import {jsonArrayMember, jsonMember, jsonObject} from "typedjson";
import * as moment from "moment";
import {Moment} from "moment";

@jsonObject
export class BcfTopicAuthorizationMap {
  @jsonArrayMember(String)
  topic_actions:string[];

  @jsonArrayMember(String)
  topic_status:string[];
}

@jsonObject
export class BcfTopicResource {

  @jsonMember
  guid:string;

  @jsonMember
  topic_type:string;

  @jsonMember
  topic_status:string;

  @jsonMember
  priority:string;

  @jsonArrayMember(String)
  reference_links:string[];

  @jsonMember
  title:string;

  @jsonMember({ preserveNull: true })
  index:number|null;

  @jsonArrayMember(String)
  labels:string[];

  @jsonMember({ deserializer: value => moment(value), serializer: (timestamp:Moment) => timestamp.toISOString() })
  creation_date:Moment;

  @jsonMember
  creation_author:string;

  @jsonMember({ deserializer: value => moment(value), serializer: (timestamp:Moment) => timestamp.toISOString() })
  modified_date:Moment;

  @jsonMember({ preserveNull: true })
  modified_author:string|null;

  @jsonMember
  assigned_to:string;

  @jsonMember({ preserveNull: true })
  stage:string|null;

  @jsonMember
  description:string;

  @jsonMember({
    deserializer: value => moment(value),
    serializer: (timestamp:Moment) => timestamp.format('YYYY-MM-DD')
  })
  due_date:Moment;

  @jsonMember
  authorization:BcfTopicAuthorizationMap;
}
