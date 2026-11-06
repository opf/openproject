import type { AttributeChoice } from './pending';
import { createDocumentMemory } from '../../utils/documentMemory';

const memory = createDocumentMemory<AttributeChoice>();

export const lastChoice = memory.recall;
export const rememberChoice = memory.remember;
export const forgetChoice = memory.forget;
