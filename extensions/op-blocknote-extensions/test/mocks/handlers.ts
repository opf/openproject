import { http, HttpResponse } from 'msw';

export const mockWorkPackage = {
  id: 123,
  displayId: '123',
  subject: 'Fix login bug',
  _links: {
    self:   { href: '/api/v3/work_packages/123' },
    type:   { title: 'Bug',         href: '/api/v3/types/1'    },
    status: { title: 'In Progress', href: '/api/v3/statuses/1' },
    assignee: null,
  },
};

export const mockWorkPackage2 = {
  id: 456,
  displayId: '456',
  subject: 'Add dark mode',
  _links: {
    self:   { href: '/api/v3/work_packages/456' },
    type:   { title: 'Feature', href: '/api/v3/types/2' },
    status: { title: 'Open',    href: '/api/v3/statuses/2' },
    assignee: null,
  },
};

export const mockWorkPackageWithSemanticId = {
  id: 789,
  displayId: 'DWPS-1',
  subject: 'Semantic ID work package',
  _links: {
    self:   { href: '/api/v3/work_packages/789' },
    type:   { title: 'Feature', href: '/api/v3/types/2' },
    status: { title: 'Open',    href: '/api/v3/statuses/2' },
    assignee: null,
  },
};

export const mockCreatedWorkPackage = {
  id: 999,
  displayId: '999',
  subject: 'Freshly created work package',
  _links: {
    self:   { href: '/api/v3/work_packages/999' },
    type:   { title: 'Task', href: '/api/v3/types/1'    },
    status: { title: 'New',  href: '/api/v3/statuses/1' },
    assignee: null,
  },
};

const subjectSchema = {
  type: 'String', name: 'Subject', required: true, hasDefault: false, writable: true, maxLength: 255,
};

const projectSchema = {
  type: 'Project', name: 'Project', required: true, hasDefault: false, writable: true, location: '_links',
  _links: { allowedValues: { href: '/api/v3/work_packages/available_projects' } },
};

const typeSchema = {
  type: 'Type', name: 'Type', required: true, hasDefault: false, writable: true, location: '_links',
  _links: {
    allowedValues: [
      { href: '/api/v3/types/1', title: 'Task' },
      { href: '/api/v3/types/2', title: 'Bug' },
    ],
  },
};

const assigneeSchema = {
  type: 'User', name: 'Assignee', required: false, hasDefault: false, writable: true, location: '_links',
  _links: { allowedValues: { href: '/api/v3/projects/1/available_assignees' } },
};

const prioritySchema = {
  type: 'Priority', name: 'Priority', required: true, hasDefault: true, writable: true, location: '_links',
  _links: { allowedValues: [{ href: '/api/v3/priorities/8', title: 'Normal' }] },
};

const statusSchema = {
  type: 'Status', name: 'Status', required: true, hasDefault: true, writable: true, location: '_links',
  _links: {
    allowedValues: [
      { href: '/api/v3/statuses/1', title: 'New' },
      { href: '/api/v3/statuses/2', title: 'In progress' },
    ],
  },
};

const supervisorSchema = {
  type: 'User', name: 'Supervisor', required: true, hasDefault: false, writable: true, location: '_links',
  _links: {
    allowedValues: {
      href: '/api/v3/principals?filters=%5B%7B%22status%22%3A%7B%22operator%22%3A%22!%22%2C%22values%22%3A%5B%223%22%5D%7D%7D%5D&pageSize=-1',
    },
  },
};

const needsDocumentationSchema = {
  type: 'Boolean', name: 'Needs documentation', required: true, hasDefault: false, writable: true,
};

const departmentSchema = {
  type: 'CustomOption', name: 'Department', required: true, hasDefault: false, writable: true, location: '_links',
  _links: {
    allowedValues: [
      { href: '/api/v3/custom_options/7', title: 'Design' },
      { href: '/api/v3/custom_options/8', title: 'Development' },
    ],
  },
};

interface FormRequestBody {
  _links?:Record<string, { href?:string }>;
}

function createFormFor(body:FormRequestBody) {
  const projectHref = body._links?.project?.href;
  const typeHref = body._links?.type?.href;

  const schema:Record<string, unknown> = { _type: 'Schema', subject: subjectSchema, project: projectSchema };
  const links:Record<string, { href:string }> = {};

  if (projectHref) {
    Object.assign(schema, { type: typeSchema, assignee: assigneeSchema, priority: prioritySchema });
    links.project = { href: projectHref };
    links.priority = { href: '/api/v3/priorities/8' };
    links.type = { href: '/api/v3/types/1' };
  }

  if (projectHref && typeHref) {
    Object.assign(schema, {
      status: statusSchema,
      customField1: supervisorSchema,
      customField2: needsDocumentationSchema,
      customField3: departmentSchema,
    });
    links.type = { href: typeHref };
    links.status = { href: '/api/v3/statuses/1' };
  }

  return {
    _type: 'Form',
    _embedded: {
      payload: { subject: null, scheduleManually: false, _links: links },
      schema,
      validationErrors: {},
    },
  };
}

function filterValues(request:Request, name:string):string[] | undefined {
  const raw = new URL(request.url).searchParams.get('filters');
  if (!raw) return undefined;

  try {
    const filters = JSON.parse(raw) as Record<string, { values?:string[] } | undefined>[];
    return filters.find((filter) => filter[name])?.[name]?.values;
  } catch { return undefined; }
}

function narrowed<T extends { id:number; name:string }>(elements:T[], request:Request) {
  const ids = filterValues(request, 'id');
  const term = (filterValues(request, 'typeahead')?.[0] ?? '').trim().toLowerCase();

  const matching = elements
    .filter((element) => !ids || ids.includes(String(element.id)))
    .filter((element) => !term || element.name.toLowerCase().includes(term));

  return HttpResponse.json({ _embedded: { elements: matching } });
}

export const handlers = [
  http.get('http://localhost:3000/api/v3/work_packages/available_projects', ({ request }) =>
    narrowed([
      { id: 1, name: 'Demo project', _links: { self: { href: '/api/v3/projects/1' } } },
      { id: 2, name: 'Scrum project', _links: { self: { href: '/api/v3/projects/2' } } },
    ], request)
  ),

  http.get('http://localhost:3000/api/v3/projects/:id/available_assignees', ({ request }) =>
    narrowed([
      { id: 5, name: 'Elif Yildiz', _links: { self: { href: '/api/v3/users/5' } } },
      { id: 6, name: 'Bianca Fuchs', _links: { self: { href: '/api/v3/users/6' } } },
    ], request)
  ),

  http.get('http://localhost:3000/api/v3/principals', ({ request }) =>
    narrowed([
      { id: 7, name: 'Anna Kovalenko', _links: { self: { href: '/api/v3/users/7' } } },
      { id: 8, name: 'Peter Lang', _links: { self: { href: '/api/v3/users/8' } } },
    ], request)
  ),

  http.post('http://localhost:3000/api/v3/work_packages/form', async ({ request }) =>
    HttpResponse.json(createFormFor(await request.json() as FormRequestBody))
  ),

  http.post('http://localhost:3000/api/v3/work_packages', async ({ request }) => {
    const body = await request.json() as { subject?:string };
    if (!body.subject) {
      return HttpResponse.json({ _type: 'Error', message: 'Subject can\'t be blank.' }, { status: 422 });
    }
    return HttpResponse.json({ ...mockCreatedWorkPackage, subject: body.subject }, { status: 201 });
  }),

  http.get('http://localhost:3000/api/v3/types', () =>
    HttpResponse.json({
      _embedded: {
        elements: [
          { id: '1', color: '#D35400' },
          { id: '2', color: '#27AE60' },
        ],
      },
    })
  ),

  http.get('http://localhost:3000/api/v3/statuses', () =>
    HttpResponse.json({
      _embedded: {
        elements: [
          { id: '1', color: '#2980B9' },
          { id: '2', color: '#95A5A6' },
        ],
      },
    })
  ),

  http.get('http://localhost:3000/api/v3/work_packages/:id', ({ params }) => {
    const raw = String(params.id);
    if (raw === '999') return HttpResponse.json(mockCreatedWorkPackage);
    if (raw === '789' || raw === 'DWPS-1') return HttpResponse.json(mockWorkPackageWithSemanticId);
    if (raw === '456') return HttpResponse.json(mockWorkPackage2);
    const id = Number(raw);
    return HttpResponse.json({ ...mockWorkPackage, id, displayId: String(id) });
  }),

  http.get('http://localhost:3000/api/v3/work_packages', () =>
    HttpResponse.json({
      _embedded: { elements: [mockWorkPackage, mockWorkPackage2, mockWorkPackageWithSemanticId] },
    })
  ),
];
