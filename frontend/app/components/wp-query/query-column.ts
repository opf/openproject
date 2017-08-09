
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';
export const queryColumnTypes = {
  PROPERTY: 'QueryColumn::Property',
  RELATION_OF_TYPE: 'QueryColumn::RelationOfType',
  RELATION_TO_TYPE: 'QueryColumn::RelationToType',
};

export function isRelationColumn(column:QueryColumn) {
  const relationTypes = [queryColumnTypes.RELATION_TO_TYPE, queryColumnTypes.RELATION_OF_TYPE];
  return relationTypes.indexOf(column._type) >= 0;
}

/**
 * A reference to a query column object as returned from the API.
 */
export interface QueryColumn extends HalResource {
  id:string;
  name:string;
  _links?: {
    self:{ href:string, title:string };
  };
}

export interface TypeRelationQueryColumn extends QueryColumn {
  type:{ href: string, name:string },
  _links?: {
    self:{ href:string, title:string },
    type:{ href:string, title:string }
  }
}

export interface RelationQueryColumn extends QueryColumn {
  relationType: string;
}
