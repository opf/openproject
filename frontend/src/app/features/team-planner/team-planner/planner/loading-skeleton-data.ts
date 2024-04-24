import * as moment from 'moment-timezone';

export const skeletonResources = [
  {
    id: 'skeleton-resource-1',
    title: '',
    href: 'skeleton-resource-1',
  },
  {
    id: 'skeleton-resource-2',
    title: '',
    href: 'skeleton-resource-2',
  },
  {
    id: 'skeleton-resource-3',
    title: '',
    href: 'skeleton-resource-3',
  },
];

const baseSkeleton = {
  editable: false,
  eventStartEditable: false,
  eventDurationEditable: false,
  allDay: true,
  backgroundColor: '#FFFFFF',
  borderColor: '#FFFFFF',
  title: '',
};

export const skeletonEvents = [
  {
    ...baseSkeleton,
    id: 'skeleton-1',
    resourceId: skeletonResources[0].id,
    start: moment().subtract(1, 'days').toDate(),
    end: moment().add(1, 'day').toDate(),
    viewBox: '0 0 800 80',
  },
  {
    ...baseSkeleton,
    id: 'skeleton-2',
    resourceId: skeletonResources[1].id,
    start: moment().subtract(3, 'days').toDate(),
    end: moment().toDate(),
    viewBox: '0 0 1200 80',
  },
  {
    ...baseSkeleton,
    id: 'skeleton-3',
    resourceId: skeletonResources[2].id,
    start: moment().toDate(),
    end: moment().add(3, 'days').toDate(),
    viewBox: '0 0 1200 80',
  },
];
