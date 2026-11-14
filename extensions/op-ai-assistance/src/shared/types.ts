//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

export type ProposalScope = 'changes' | 'comment_only' | 'read_only';

export interface Skill {
  id:string;
  label:string;
  description:string;
  icon:string;
  prompt:string;
  scope:ProposalScope;
  answersAtOnce:boolean;
  useTools:boolean;
}

export type AuthMode = 'session' | 'token';

export type LlmProvider = 'anthropic' | 'openai';

export interface Settings {
  instanceUrl:string;
  authMode:AuthMode;
  apiToken:string;
  provider:LlmProvider;
  llmKey:string;
  llmBaseUrl:string;
  model:string;
  instructions:string;
  skills:Skill[];
}

export type Severity = 'high' | 'medium' | 'low';

export type ChangeKey =
  | 'subject'
  | 'description'
  | 'status'
  | 'priority'
  | 'assigned_to'
  | 'responsible'
  | 'start_date'
  | 'due_date'
  | 'comment';

export interface ChangeAction {
  key:ChangeKey;
  // The text, the ISO date, or the API v3 href of the chosen value.
  value:string;
  label:string;
}

export type ProposalState = 'open' | 'applied' | 'dismissed';

export interface Proposal {
  id:string;
  text:string;
  severity:Severity | null;
  area:string | null;
  evidence:string[];
  actions:ChangeAction[];
  state:ProposalState;
  dismissReason?:string;
  // The description when the proposal was made, to refuse a description change on a newer one.
  baseDescription?:string;
}

export type RunEvent =
  | { type:'request'; model:string; system:string; message:string; tools:number }
  | { type:'thought'; text:string }
  | { type:'tool_call'; name:string; arguments:Record<string, unknown>; seconds?:number; size?:number; result?:string; error?:string; refused?:boolean; repeated?:boolean }
  | { type:'answer'; seconds:number; toolCalls:number; content:string }
  | { type:'stored'; findings:number; stored:number; dropped:{ reason:string; proposal:unknown }[] }
  | { type:'note'; text:string }
  | { type:'failure'; error:string };

export type MessageRole = 'start' | 'user' | 'assistant';

export interface ChatMessage {
  id:string;
  role:MessageRole;
  content:string;
  createdAt:string;
  status:'done' | 'failed';
  proposals:Proposal[];
  events:RunEvent[];
}

export interface Chat {
  id:string;
  skillId:string;
  workPackageId:string;
  createdAt:string;
  messages:ChatMessage[];
}

export interface RawProposal {
  text?:unknown;
  severity?:unknown;
  area?:unknown;
  evidence?:unknown;
  changes?:unknown;
}

export interface RawAnswer {
  answer?:unknown;
  proposals?:unknown;
}
