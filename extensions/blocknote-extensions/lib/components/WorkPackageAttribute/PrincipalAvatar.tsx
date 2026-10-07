import { useState } from 'react';
import { avatarUrlOf } from '../../services/openProjectApi';
import type { Principal } from './attributes';
import { avatarColorOf, initialsOf } from './avatars';
import { Avatar, AvatarPicture } from './atoms';

export function PrincipalAvatar({ principal }:{ principal:Principal }) {
  const [loaded, setLoaded] = useState(false);
  const url = avatarUrlOf(principal.href);

  // The initials stay underneath until the picture is there, and for good when there is none.
  return (
    <Avatar data-initials={initialsOf(principal.name)} $color={avatarColorOf(principal)}>
      {url && <AvatarPicture src={url} alt="" draggable={false} $loaded={loaded} onLoad={() => setLoaded(true)} />}
    </Avatar>
  );
}
