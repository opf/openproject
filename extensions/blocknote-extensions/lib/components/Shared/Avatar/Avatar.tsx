import { useState } from 'react';
import styled from 'styled-components';
import { avatarUrlOf, userApiPath } from '../../../services/openProjectApi';
import { avatarColorOf, initialsOf } from './avatars';

interface AvatarProps {
  userId:string | number;
  name:string;
  size:number;
}

const Circle = styled.span.attrs({ className: 'op-bn-avatar' })<{ $size:number; $color:string }>`
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: none;
  width: ${({ $size }) => $size}px;
  height: ${({ $size }) => $size}px;
  border-radius: 50%;
  overflow: hidden;
  background: ${({ $color }) => $color};
  color: #fff;
  font-size: ${({ $size }) => Math.round($size * 0.45)}px;
  font-weight: 600;
  line-height: 1;
  vertical-align: middle;
`;

const Image = styled.img.attrs({ alt: '', draggable: false })`
  width: 100%;
  height: 100%;
  object-fit: cover;
`;

export function Avatar({ userId, name, size }:AvatarProps) {
  const [imageLoaded, setImageLoaded] = useState(false);
  const href = userApiPath(userId);

  return (
    <Circle
      data-testid="avatar"
      $size={size}
      $color={avatarColorOf({ name, href })}
      aria-hidden
      className={imageLoaded ? 'op-bn-avatar--image' : undefined}
    >
      <Image
        src={avatarUrlOf(href)}
        hidden={!imageLoaded}
        onLoad={() => setImageLoaded(true)}
      />
      {!imageLoaded && initialsOf(name)}
    </Circle>
  );
}
