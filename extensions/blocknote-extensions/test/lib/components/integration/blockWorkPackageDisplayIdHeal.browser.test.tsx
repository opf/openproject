import { describe, it, expect } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { computeWorkPackageBlockExternalData } from '../../../../lib/components/BlockWorkPackage/externalHtml';

describe('BlockWorkPackage — displayId self-healing', () => {
  it('backfills displayId on a legacy block that was stored without it', async () => {
    let capturedEditor:any;
    renderEditor({ onEditor: (editor) => { capturedEditor = editor; } });

    // Wait for the editor to mount before touching it programmatically.
    await expect.element(page.getByRole('textbox')).toBeVisible();

    // Simulate a block from an old document: wpid present, displayId empty.
    // WP #789 has displayId "DWPS-1" in the MSW mock — distinct from its numeric id,
    // so we can tell whether the semantic ID or the numeric fallback was used.
    capturedEditor.insertBlocks(
      [{ type: 'openProjectWorkPackageBlock', props: { wpid: 789, displayId: '', size: 'm' } }],
      capturedEditor.document[0],
      'after'
    );

    const blockId = capturedEditor.document.find(
      (block:any) => block.type === 'openProjectWorkPackageBlock'
    ).id;

    expect(
      capturedEditor.document.find((b:any) => b.id === blockId).props.displayId
    ).toBe('');

    // The card becoming visible means useWorkPackage resolved; the displayId backfill runs in a post-render effect.
    await expect.element(page.getByText('Semantic ID work package')).toBeVisible();

    await expect
      .poll(() => (capturedEditor.getBlock(blockId)?.props)?.displayId as string | undefined)
      .toBe('DWPS-1');

    const block = capturedEditor.getBlock(blockId);
    expect((block.props).displayId).toBe('DWPS-1');

    // copy-paste and static-spec output must use the semantic ID, not the numeric fallback
    const data = computeWorkPackageBlockExternalData(block.props);
    expect(data?.text).toContain('DWPS-1');
    expect(data?.text).not.toContain('789');
  });
});
