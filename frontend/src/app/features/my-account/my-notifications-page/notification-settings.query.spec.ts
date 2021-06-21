import { NotificationSettingsQuery } from './notification-settings.query';
import { NotificationSettingsStore } from "./notification-settings.store";

describe('NotificationSettingsQuery', () => {
  it('should create an instance', () => {
    expect(new NotificationSettingsQuery(new NotificationSettingsStore)).toBeTruthy();
  });
});
