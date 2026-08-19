export interface Document {
  id: string;
  title: string;
  content: string;
}

type Link = { href: string, method?: string };
export interface ApiResponseDocument {
  _embedded: {
    attachments: { total: number, count: number },
    project: { name: string },
  },
  _links: {
    attachments: Link,
    addAttachment: Link,
    self: Link,
    update?: Link,
    project: Link,
  },
  _type: string,
  id: string,
  title: string,
  description: {
    format: string,
    raw: string,
    html: string,
  },
  contentBinary: string,
  createdAt: string,
  updatedAt: string,
}
