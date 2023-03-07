export default (
  tokens:{[name:string]:string},
  filterFn:(key:string) => boolean,
) => Object
  .keys(tokens)
  .filter(filterFn)
  .reduce((obj, key) => ({ ...obj, [key]: tokens[key] }), {});
