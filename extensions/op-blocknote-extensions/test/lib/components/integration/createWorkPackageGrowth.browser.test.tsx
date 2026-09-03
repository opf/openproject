import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { recordFrames, untilStill } from '../../../helpers/animationHelpers';
import {
  modalBody,
  modalPanel,
  openCreateModal,
  pickProject,
  selectOptionNamed,
} from '../../../helpers/createWorkPackageHelpers';

interface Frame {
  height:number;
  growing:boolean;
}

const recordPanel = () => recordFrames<Frame>(() => ({
  height: modalPanel().getBoundingClientRect().height,
  growing: modalBody().dataset.growing !== undefined,
}));

const panelHeight = ():number => modalPanel().getBoundingClientRect().height;

function expectCrossing(frames:Frame[], from:number, to:number) {
  const crossed = frames.map(({ height }) => height);

  expect(new Set(crossed).size).toBeGreaterThan(2);
  expect(Math.min(...crossed)).toBe(Math.min(from, to));
  expect(Math.max(...crossed)).toBeLessThanOrEqual(Math.max(from, to));
}

describe('Create work package - growing to fit its fields', () => {
  it('crosses to the height the picked project brings rather than jumping onto it', async () => {
    renderEditor();
    await openCreateModal();
    await userEvent.fill(page.getByLabelText('Subject *'), 'Fix the header alignment');
    await untilStill(modalPanel());
    const before = panelHeight();

    const recorded = recordPanel();
    await pickProject();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await untilStill(modalPanel());
    recorded.stop();

    expect(panelHeight()).toBeGreaterThan(before);
    expectCrossing(recorded.frames, before, panelHeight());
  });

  it('crosses back down when the picks that brought the fields are taken away', async () => {
    renderEditor();
    await openCreateModal();
    await pickProject();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await selectOptionNamed('Type *', 'Task');
    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
    await untilStill(modalPanel());
    const before = panelHeight();

    const recorded = recordPanel();
    await userEvent.fill(page.getByLabelText('Project *'), '');
    await expect.element(page.getByLabelText('Supervisor *')).not.toBeInTheDocument();
    await untilStill(modalPanel());
    recorded.stop();

    expect(panelHeight()).toBeLessThan(before);
    expectCrossing(recorded.frames, before, panelHeight());
  });

  it('holds the scrollbar of the body back only for as long as the panel moves', async () => {
    renderEditor();
    await openCreateModal();
    await untilStill(modalPanel());
    expect(modalBody().dataset.growing).toBeUndefined();

    const recorded = recordPanel();
    await pickProject();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await untilStill(modalPanel());
    recorded.stop();

    expect(recorded.frames.some(({ growing }) => growing)).toBe(true);
    expect(modalBody().dataset.growing).toBeUndefined();
    expect(getComputedStyle(modalBody()).overflowY).toBe('auto');
  });
});
