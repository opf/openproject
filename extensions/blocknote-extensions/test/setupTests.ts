import { beforeAll, afterAll, beforeEach } from 'vitest';
import { page } from 'vitest/browser';
import { worker } from './mocks/browser';
import { initializeOpBlockNoteExtensions } from '../lib';
import { clearWorkPackageCache } from '../lib/services/workPackageLoader';
import * as createWorkPackageChoice from '../lib/components/CreateWorkPackage/lastChoice';
import * as attributeChoice from '../lib/components/WorkPackageAttribute/lastChoice';
import { clearPickerCache } from '../lib/components/CreateWorkPackage/usePickerOptions';
import { clearDatePickerSettings } from '../lib/components/CreateWorkPackage/datePickerSettings';
import { whenCreateWorkPackagePermissionKnown } from '../lib/services/openProjectApi';
import { DESKTOP } from './helpers/createWorkPackageHelpers';

beforeEach(async () => {
  await page.viewport(DESKTOP.width, DESKTOP.height);
  clearWorkPackageCache();
  createWorkPackageChoice.forgetChoice();
  attributeChoice.forgetChoice();
  clearPickerCache();
  clearDatePickerSettings();
});

beforeAll(async () => {
  await worker.start({ onUnhandledFrame: 'bypass' });
  initializeOpBlockNoteExtensions({ baseUrl: 'http://localhost:3000', locale: 'en' });
  await whenCreateWorkPackagePermissionKnown();
});

afterAll(() => {
  worker.stop();
});