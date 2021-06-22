import { HalSourceLink } from "core-app/features/hal/resources/hal-resource";
import { NotificationSettingChannel } from "core-app/features/my-account/my-notifications-page/state/notification-settings.store";

export interface NotificationSetting {
  _links:{ project:HalSourceLink };
  channel:NotificationSettingChannel;
  watched:boolean;
  involved:boolean;
  mentioned:boolean;
  all:boolean;
}

export function buildNotificationSetting(project:null|HalSourceLink, params:Partial<NotificationSetting>):NotificationSetting {
  return {
    _links: {
      project: {
        href: project ? project.href : null,
        title: project?.title
      }
    },
    involved: true,
    mentioned: true,
    watched: false,
    all: false,
    channel: "in_app",
    ...params
  };
}