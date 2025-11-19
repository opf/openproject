export interface WorkPackage {
  id: string;
  subject: string;
  status?: string | null;
  assignee?: string | null;
  href?: string | null;
  lockVersion?: number | null;
  _links?: {
    self: { href: string };
    status: { title: string; href: string } | null;
    assignee: { title: string; href: string } | null;
    type: { title: string; href: string } | null;
  } | null;
}

export interface WorkPackageCollection {
  _embedded: {
    elements: WorkPackage[];
  };
}

export interface StatusCollection {
  _embedded?: {
    elements?: Array<{
      id: string;
      name: string;
      isClosed: boolean;
      color: string;
      _links: {
        self: { href: string };
      }
    }>;
  },
}

export interface TypeCollection {
  _embedded?: {
    elements?: Array<{
      id: string;
      name: string;
      color: string;
      _links: {
        self: { href: string; };
      }
    }>;
  },
}

export interface OpenProjectResponse {
  _embedded?: {
    elements?: Array<{
      id: string;
      name: string;
      _links?: { self: { href: string } };
    }>;
  };
}