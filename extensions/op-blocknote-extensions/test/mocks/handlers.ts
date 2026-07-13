import { http, HttpResponse } from 'msw';

export const mockWorkPackage = {
  id: 123,
  displayId: '123',
  subject: 'Fix login bug',
  _links: {
    self:   { href: '/api/v3/work_packages/123' },
    type:   { title: 'Bug',         href: '/api/v3/types/1'    },
    status: { title: 'In Progress', href: '/api/v3/statuses/1' },
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
  },
};

export const handlers = [
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