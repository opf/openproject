import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';

export type NotificationSettingChannel = 'mail'|'mail_digest'|'in_app';

export interface NotificationSetting {
  _links:{ project:HalSourceLink };
  channel:NotificationSettingChannel;
  watched:boolean;
  involved:boolean;
  mentioned:boolean;
  workPackageCommented:boolean;
  workPackageCreated:boolean;
  workPackageProcessed:boolean;
  all:boolean;
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
    all: false,
    channel: 'in_app',
    ...params,
  };
}
