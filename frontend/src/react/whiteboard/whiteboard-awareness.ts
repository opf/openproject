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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import type { HocuspocusProvider } from '@hocuspocus/provider';
import type { Collaborator, SocketId } from '@excalidraw/excalidraw/types';

export interface WhiteboardUser {
  id:number;
  name:string;
  avatarUrl?:string|null;
}

interface AwarenessState {
  user?:WhiteboardUser & { color:Collaborator['color'] };
  pointer?:Collaborator['pointer'];
  button?:Collaborator['button'];
  selectedElementIds?:Collaborator['selectedElementIds'];
  userState?:Collaborator['userState'];
}

const POINTER_THROTTLE_MS = 40;

// Same hue as the avatar placeholder of the principal renderer, so people keep their colour across OpenProject.
function userHue(user:WhiteboardUser):number {
  const value = `${user.id}${user.name}`;
  let hash = 0;
  for (let i = 0; i < value.length; i++) {
    hash = value.charCodeAt(i) + ((hash << 5) - hash);
  }
  return hash % 360;
}

export function userColor(user:WhiteboardUser):Collaborator['color'] {
  const hue = userHue(user);
  return { background: `hsl(${hue}, 50%, 30%)`, stroke: `hsl(${hue}, 50%, 45%)` };
}

/**
 * Publishes the local user's pointer, selection and idle state through the
 * Hocuspocus awareness channel, and turns everybody's state into the
 * collaborators map Excalidraw renders as avatars, cursors and selections.
 */
export class WhiteboardAwareness {
  private lastPointerSent = 0;
  private lastSelectionKey = '';

  constructor(
    private readonly provider:HocuspocusProvider,
    user:WhiteboardUser,
    private readonly onCollaboratorsChange:(collaborators:Map<SocketId, Collaborator>) => void,
  ) {
    this.awareness.setLocalStateField('user', { ...user, color: userColor(user) });
    this.awareness.setLocalStateField('userState', 'active');
    this.awareness.on('change', this.publishCollaborators);
    document.addEventListener('visibilitychange', this.onVisibilityChange);
    this.publishCollaborators();
  }

  destroy():void {
    this.awareness.off('change', this.publishCollaborators);
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    this.awareness.setLocalState(null);
  }

  updatePointer(pointer:NonNullable<Collaborator['pointer']>, button:Collaborator['button']):void {
    const now = Date.now();
    if (now - this.lastPointerSent < POINTER_THROTTLE_MS) return;

    this.lastPointerSent = now;
    this.awareness.setLocalStateField('pointer', pointer);
    this.awareness.setLocalStateField('button', button);
  }

  updateSelection(selectedElementIds:Collaborator['selectedElementIds']):void {
    const key = Object.keys(selectedElementIds ?? {}).sort().join(',');
    if (key === this.lastSelectionKey) return;

    this.lastSelectionKey = key;
    this.awareness.setLocalStateField('selectedElementIds', selectedElementIds);
  }

  private get awareness() {
    return this.provider.awareness!;
  }

  private onVisibilityChange = ():void => {
    this.awareness.setLocalStateField('userState', document.hidden ? 'away' : 'active');
  };

  private publishCollaborators = ():void => {
    const collaborators = new Map<SocketId, Collaborator>();

    (this.awareness.getStates() as Map<number, AwarenessState>).forEach((state, clientId) => {
      if (!state.user) return;

      const isCurrentUser = clientId === this.awareness.clientID;
      collaborators.set(String(clientId) as SocketId, {
        id: String(state.user.id),
        socketId: String(clientId) as SocketId,
        username: state.user.name,
        avatarUrl: state.user.avatarUrl ?? undefined,
        color: state.user.color,
        isCurrentUser,
        pointer: isCurrentUser ? undefined : state.pointer,
        button: state.button,
        selectedElementIds: isCurrentUser ? undefined : state.selectedElementIds,
        userState: state.userState,
      });
    });

    this.onCollaboratorsChange(collaborators);
  };
}
