import styled from 'styled-components';

export const SearchMessage = styled.div.attrs({
  className: 'op-bn-search--message',
  role: 'status',
})`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--spacer-m);
  padding: var(--spacer-m) var(--spacer-l);
  font-size: 0.85em;
  color: var(--bn-colors-highlights-gray-text, #888);
`;
