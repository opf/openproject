export const skeletonResources = [
  {
    id: 'skeleton-1',
    title: '',
    href:'',
    dataLoaded: false,
  },
  {
    id: 'skeleton-2',
    title: '',
    href:'',
    dataLoaded: false,
  },
  {
    id: 'skeleton-3',
    title: '',
    href:'',
    dataLoaded: false,
  },
];

export const skeletonEvents = [
  {
    id: 'skeleton-1',
    resourceId: skeletonResources[0].id,
    title: '',
    start: moment().subtract(1, 'days').toDate(),
    end: moment().toDate(),
    backgroundColor: '#FFFFFF',
    borderColor: '#FFFFFF',
    allDay: true,
    dataLoaded: false,
    width: 100
  },
  {
    id: 'skeleton-2',
    resourceId: skeletonResources[1].id,
    title: '',
    start: moment().subtract(3, 'days').toDate(),
    end: moment().subtract(1, 'days').toDate(),
    backgroundColor: '#FFFFFF',
    borderColor: '#FFFFFF',
    allDay: true,
    dataLoaded: false,
    width: 150
  },
  {
    id: 'skeleton-3',
    resourceId: skeletonResources[2].id,
    title: '',
    start: moment().toDate(),
    end: moment().add(2, 'days').toDate(),
    backgroundColor: '#FFFFFF',
    borderColor: '#FFFFFF',
    allDay: true,
    dataLoaded: false,
    width: 150
  },
]
