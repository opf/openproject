import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';

export interface INotificationSetting {
  _links:{ project:HalSourceLink };
  watched:boolean;
  assignee:boolean;
  responsible:boolean;
  shared:boolean;
  mentioned:boolean;
  workPackageCommented:boolean;
  workPackageCreated:boolean;
  workPackageProcessed:boolean;
  workPackagePrioritized:boolean;
  workPackageScheduled:boolean;
  newsAdded:boolean;
  newsCommented:boolean;
  documentAdded:boolean;
  forumMessages:boolean;
  wikiPageAdded:boolean;
  wikiPageUpdated:boolean;
  membershipAdded:boolean;
  membershipUpdated:boolean;
  startDate?:string|null;
  dueDate?:string|null;
  overdue?:string|null;
}

export function buildNotificationSetting(project:null|HalSourceLink, params:Partial<INotificationSetting>):INotificationSetting {
  return {
    _links: {
      project: {
        href: project ? project.href : null,
        title: project?.title,
      },
    },
    assignee: true,
    responsible: true,
    shared: true,
    mentioned: true,
    watched: true,
    workPackageCommented: true,
    workPackageCreated: true,
    workPackageProcessed: true,
    workPackagePrioritized: true,
    workPackageScheduled: true,
    newsAdded: true,
    newsCommented: true,
    documentAdded: true,
    forumMessages: true,
    wikiPageAdded: true,
    wikiPageUpdated: true,
    membershipAdded: true,
    membershipUpdated: true,
    startDate: 'P1D',
    dueDate: 'P1D',
    overdue: null,
    ...params,
  };
}
