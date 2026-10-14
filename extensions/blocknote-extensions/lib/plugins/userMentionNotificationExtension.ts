import { createExtension } from '@blocknote/core';
import { userMentionNotificationPlugin } from './userMentionNotificationPlugin';

// Registered on the editor because BlockNote ignores the extensions of inline content specs.
export const UserMentionNotificationExtension = createExtension(() => ({
  key: 'userMentionNotification',
  prosemirrorPlugins: [userMentionNotificationPlugin()],
}))();
