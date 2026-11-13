import { beforeAll, afterAll, beforeEach } from 'vitest';
import { page } from 'vitest/browser';
import { worker } from './mocks/browser';
import { initializeOpBlockNoteExtensions } from '../lib';
import { clearWorkPackageCache } from '../lib/services/workPackageLoader';
import * as createWorkPackageChoice from '../lib/components/CreateWorkPackage/lastChoice';
import * as attributeChoice from '../lib/components/WorkPackageAttribute/lastChoice';
import { clearPickerCache } from '../lib/components/CreateWorkPackage/usePickerOptions';
import { clearNonWorkingDays } from '../lib/components/CreateWorkPackage/nonWorkingDays';
import { clearDateTimeSettings } from '../lib/services/dateTimeSettings';
import { whenCreateWorkPackagePermissionKnown } from '../lib/services/openProjectApi';
import { DESKTOP } from './helpers/createWorkPackageHelpers';

beforeEach(async () => {
  await page.viewport(DESKTOP.width, DESKTOP.height);
  clearWorkPackageCache();
  createWorkPackageChoice.forgetChoice();
  attributeChoice.forgetChoice();
  clearPickerCache();
  clearDateTimeSettings();
  clearNonWorkingDays();
});

beforeAll(async () => {
  await worker.start({ onUnhandledRequest: 'bypass' });
  initializeOpBlockNoteExtensions({ baseUrl: 'http://localhost:3000', locale: 'en' });
  await whenCreateWorkPackagePermissionKnown();
});

afterAll(() => {
  worker.stop();
});