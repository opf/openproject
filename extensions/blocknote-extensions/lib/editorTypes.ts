import type { BlockNoteEditor } from '@blocknote/core';

// The schema generics differ per call site and none of our helpers depend on
// them, so they stay open rather than being threaded through every signature.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type AnyEditor = BlockNoteEditor<any, any, any>;
