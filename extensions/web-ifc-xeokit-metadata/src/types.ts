export interface MetaObject {
  id: string;
  name: string;
  type: string;
  parent: string | null;
}

export interface MetaModel {
  id: string;
  projectId: string;
  author: string;
  createdAt: string;
  schema: string;
  creatingApplication: string;
  metaObjects: MetaObject[];
}
