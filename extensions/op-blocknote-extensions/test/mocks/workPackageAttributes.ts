export const ATTRIBUTE_SCHEMA_HREF = '/api/v3/work_packages/schemas/1-2';

const field = (type:string, name:string, location?:string) => ({
  type, name, required: false, hasDefault: false, writable: true, ...(location ? { location } : {}),
});

export const mockAttributeSchema = {
  _type: 'Schema',
  _dependencies: [],
  lockVersion: field('Integer', 'Lock Version'),
  id: field('Integer', 'ID'),
  subject: field('String', 'Subject'),
  description: field('Formattable', 'Description'),
  duration: field('Duration', 'Duration'),
  scheduleManually: field('Boolean', 'Manual scheduling'),
  startDate: field('Date', 'Start date'),
  dueDate: field('Date', 'Finish date'),
  derivedStartDate: field('Date', 'Derived start date'),
  estimatedTime: field('Duration', 'Work'),
  percentageDone: field('Integer', '% Complete'),
  createdAt: field('DateTime', 'Created on'),
  assignee: field('User', 'Assignee', '_links'),
  responsible: field('User', 'Accountable', '_links'),
  type: field('Type', 'Type', '_links'),
  status: field('Status', 'Status', '_links'),
  priority: field('Priority', 'Priority', '_links'),
  version: field('Version', 'Version', '_links'),
  targetVersions: field('[]Version', 'Version', '_links'),
  customField1: field('[]User', 'Content owner', '_links'),
  customField2: field('Boolean', 'Approved'),
  customField3: field('Float', 'Budget share'),
  customField4: field('Formattable', 'Notes'),
  customField5: field('String', 'Department'),
  _links: { self: { href: ATTRIBUTE_SCHEMA_HREF } },
};

export const mockAttributeWorkPackage = {
  _type: 'WorkPackage',
  id: 321,
  displayId: 'PROJ-321',
  subject: 'Redesign onboarding flow',
  description: { raw: 'Long text' },
  duration: 'P5D',
  scheduleManually: false,
  startDate: '2026-09-14',
  dueDate: null,
  estimatedTime: 'PT24H30M',
  percentageDone: 40,
  createdAt: '2026-09-01T08:30:00Z',
  customField2: true,
  customField3: 0.25,
  customField5: '',
  _links: {
    self: { href: '/api/v3/work_packages/321' },
    schema: { href: ATTRIBUTE_SCHEMA_HREF },
    type: { title: 'Feature', href: '/api/v3/types/2' },
    status: { title: 'In progress', href: '/api/v3/statuses/2' },
    priority: { title: 'High', href: '/api/v3/priorities/9' },
    assignee: { title: 'Mira Hofmann', href: '/api/v3/users/3' },
    responsible: { href: null },
    targetVersions: [{ title: '16.5', href: '/api/v3/versions/1' }, { title: '16.6', href: '/api/v3/versions/2' }],
    customField1: [{ title: 'Jean Cérien', href: '/api/v3/users/4' }, { title: 'Hugo Martins', href: '/api/v3/users/5' }],
  },
};

export const MILESTONE_SCHEMA_HREF = '/api/v3/work_packages/schemas/1-3';

export const mockMilestoneSchema = {
  _type: 'Schema',
  subject: field('String', 'Subject'),
  date: field('Date', 'Date'),
  status: field('Status', 'Status', '_links'),
  _links: { self: { href: MILESTONE_SCHEMA_HREF } },
};

export const mockMilestoneWorkPackage = {
  _type: 'WorkPackage',
  id: 654,
  displayId: 'PROJ-654',
  subject: 'Public beta',
  date: '2026-10-30',
  _links: {
    self: { href: '/api/v3/work_packages/654' },
    schema: { href: MILESTONE_SCHEMA_HREF },
    type: { title: 'Milestone', href: '/api/v3/types/3' },
    status: { title: 'Scheduled', href: '/api/v3/statuses/3' },
  },
};
