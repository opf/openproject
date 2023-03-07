export default ({ tokens, name }) =>
  <div
    className="colors--color"
    key={name}
  >
    <div
      className="colors--preview"
      style={{ 'backgroundColor': tokens[name] }}
    />
    <div className="colors--name">${name}</div>
    <div className="colors--value">{tokens[name]}</div>
  </div>
</div>;
