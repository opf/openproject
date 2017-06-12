
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';
export const queryColumnTypes = {
  PROPERTY: 'QueryColumn::Property',
  RELATION_OF_TYPE: 'QueryColumn::RelationOfType',
  RELATION_TO_TYPE: 'QueryColumn::RelationToType',
};


/**
 * A reference to a query column object as returned from the API.
 */
export interface QueryColumn extends HalResource {
  id:string;
  name:string;
  _links?: {
    self:{ href:string, title:string };
  }
}

export interface TypeRelationQueryColumn extends QueryColumn {
  type:{ href: string },
  _links?: {
    self:{ href:string, title:string },
    type:{ href:string }
  }
}

export interface RelationQueryColumn extends QueryColumn {
  relationType: string;
}
