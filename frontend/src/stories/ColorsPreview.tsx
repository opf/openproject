import ColorPreview from './ColorPreview.tsx';

export default ({ tokens }) => <div className="colors">
  {Object.keys(tokens)
    .filter(key => key.startsWith('spot-color-'))
    .map(name => <ColorPreview tokens={tokens} name={name}></ColorPreview>)
  }
</div>;
