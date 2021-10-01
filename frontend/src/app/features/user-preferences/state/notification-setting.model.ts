import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';

export interface NotificationSetting {
  _links:{ project:HalSourceLink };
  watched:boolean;
  involved:boolean;
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
}

export function buildNotificationSetting(project:null|HalSourceLink, params:Partial<NotificationSetting>):NotificationSetting {
  return {
    _links: {
      project: {
        href: project ? project.href : null,
        title: project?.title,
      },
    },
    involved: true,
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
    ...params,
  };
}
