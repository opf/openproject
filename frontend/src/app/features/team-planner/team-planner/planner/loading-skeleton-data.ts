export const skeletonResources = [
  {
    id: 'skeleton-1',
    title: '',
    href: '',
  },
  {
    id: 'skeleton-2',
    title: '',
    href: '',
  },
  {
    id: 'skeleton-3',
    title: '',
    href: '',
  },
];

export const skeletonEvents = [
  {
    id: 'skeleton-1',
    resourceId: skeletonResources[0].id,
    title: '',
    start: moment().subtract(1, 'days').toDate(),
    end: moment().add(1, 'day').toDate(),
    backgroundColor: '#FFFFFF',
    borderColor: '#FFFFFF',
    allDay: true,
    viewBox: '0 0 800 80',
  },
  {
    id: 'skeleton-2',
    resourceId: skeletonResources[1].id,
    title: '',
    start: moment().subtract(3, 'days').toDate(),
    end: moment().toDate(),
    backgroundColor: '#FFFFFF',
    borderColor: '#FFFFFF',
    allDay: true,
    viewBox: '0 0 1200 80',
  },
  {
    id: 'skeleton-3',
    resourceId: skeletonResources[2].id,
    title: '',
    start: moment().toDate(),
    end: moment().add(3, 'days').toDate(),
    backgroundColor: '#FFFFFF',
    borderColor: '#FFFFFF',
    allDay: true,
    viewBox: '0 0 1200 80',
  },
];
