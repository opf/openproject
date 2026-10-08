import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page } from 'vitest/browser';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
import { renderEditor } from '../../../helpers/renderEditor';

// Regression coverage for real-time collaboration privacy: a pending work
// package chip/block is only "resolvable" (shows a search dialog) on the
// client that inserted it. That gate lives entirely in a local, in-memory
// registry (`callbacks.ts`'s Map, `pendingBlockRegistry`'s Set) that is
// never synced — only the node's own props (wpid/size/displayId, or an
// empty block) travel over Yjs. These tests simulate what another
// collaborator's browser renders: the exact synced prop shape, but with no
// local registration for it.

afterEach(() => {
  cleanup();
});

describe('Pending work package chip/block privacy', () => {
  it('inline: renders nothing interactive for a pending chip that was never registered locally', async () => {
    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: 'pending:not-registered-uuid', size: 's', displayId: '' } }}
        contentRef={vi.fn()}
      />,
    );

    // No search dialog for this "foreign" pending chip.
    await expect
      .element(page.getByPlaceholder('Search by work package ID or subject'))
      .not.toBeInTheDocument();
    // No accidental work package resolution/fetch either.
    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();

    // The chip element itself exists but is empty (an inert placeholder).
    const chip = document.querySelector('.op-bn-inline-wp');
    expect(chip).not.toBeNull();
    expect(chip?.textContent).toBe('');
  });

  it('block: renders no search dropdown for a work package block that was never registered locally', async () => {
     
    let editor:any;
    renderEditor({ onEditor: (e) => { editor = e; } });
    await expect.element(page.getByRole('textbox')).toBeVisible();

    // Insert the block directly, bypassing insertBlockWorkPackage/pendingBlockRegistry.add —
    // exactly the state another collaborator's client sees after Yjs sync.
    editor.insertBlocks(
      [{ type: 'openProjectWorkPackageBlock', props: {} }],
      editor.document[0],
      'after',
    );

    await new Promise((r) => setTimeout(r, 300));

    await expect
      .element(page.getByPlaceholder('Search by work package ID or subject'))
      .not.toBeInTheDocument();
    expect(document.querySelector('input')).toBeNull();
    // No unavailable/error card either — the block genuinely has no wpid yet.
    await expect.element(page.getByText('Loading')).not.toBeInTheDocument();
    await expect.element(page.getByText('Error')).not.toBeInTheDocument();
  });
});
