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

export const SCRIPT_ID = 'op-ai-assistance';

const LLM_HOSTS = ['https://api.anthropic.com/*', 'https://api.openai.com/*'];

// Match patterns leave out the port: Firefox does not accept one, and a pattern without a
// port matches every port in both browsers.
export function originPattern(url:string):string {
  const { protocol, hostname } = new URL(url);
  return `${protocol}//${hostname}/*`;
}

// The OpenProject hosts among the granted origins: every specific host except the LLM
// providers. A broad pattern such as https://*/* never counts as a host. A custom LLM server
// on the same host as the instance (both on localhost) does not hide the instance.
export function hostsFrom(origins:string[], llmBaseUrl = '', instanceUrl = ''):string[] {
  const llm = llmBaseUrl.trim() ? originPattern(llmBaseUrl.trim()) : null;
  const instance = instanceUrl.trim() ? originPattern(instanceUrl.trim()) : null;
  const excluded = [...LLM_HOSTS, ...(llm && llm !== instance ? [llm] : [])];
  return origins.filter((origin) => !origin.includes('*.') && !/^\w+:\/\/\*\//.test(origin) && !excluded.includes(origin));
}

// The extension pages are web-accessible, so any website can frame them with any hash. An
// origin from the hash counts only when the user granted it as an OpenProject host.
export function isTrustedOrigin(origin:string | null, grantedOrigins:string[], llmBaseUrl = ''):origin is string {
  if (!origin) return false;
  try {
    const url = new URL(origin);
    return url.origin === origin && hostsFrom(grantedOrigins, llmBaseUrl, origin).includes(originPattern(origin));
  } catch {
    return false;
  }
}

export function sameOrigin(url:string | undefined, origin:string):boolean {
  try {
    return url !== undefined && new URL(url).origin === origin;
  } catch {
    return false;
  }
}
