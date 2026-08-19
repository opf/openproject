import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

export class SchemaAttributeObject<T = HalResource> {
  public type:string;

  public name:string;

  public required:boolean;

  public hasDefault:boolean;

  public writable:boolean;

  public allowedValues:T[] | CollectionResource<T>;
}
