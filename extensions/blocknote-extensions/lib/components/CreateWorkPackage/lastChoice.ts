import type { AllowedValue } from './formSchema';
import { createDocumentMemory } from '../../utils/documentMemory';

export type FormChoice = Record<string, AllowedValue>;

const memory = createDocumentMemory<FormChoice>();

export const lastChoice = ():FormChoice => memory.recall() ?? {};
export const rememberChoice = memory.remember;
export const forgetChoice = memory.forget;
