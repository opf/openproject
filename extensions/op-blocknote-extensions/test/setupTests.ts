import { beforeAll, afterAll, beforeEach } from 'vitest';
import { page } from 'vitest/browser';
import { worker } from './mocks/browser';
import { initializeOpBlockNoteExtensions } from '../lib';
import { clearWorkPackageCache } from '../lib/hooks/useWorkPackage';
import { forgetLastSelection } from '../lib/components/CreateWorkPackage/lastSelection';
import { clearPickerCache } from '../lib/components/CreateWorkPackage/usePickerOptions';
import { whenCreateWorkPackagePermissionKnown } from '../lib/services/openProjectApi';
import { DESKTOP } from './helpers/createWorkPackageHelpers';

beforeEach(async () => {
  await page.viewport(DESKTOP.width, DESKTOP.height);
  clearWorkPackageCache();
  forgetLastSelection();
  clearPickerCache();
});

beforeAll(async () => {
  await worker.start({ onUnhandledRequest: 'bypass' });
  initializeOpBlockNoteExtensions({ baseUrl: 'http://localhost:3000', locale: 'en' });
  await whenCreateWorkPackagePermissionKnown();
});

afterAll(() => {
  worker.stop();
});