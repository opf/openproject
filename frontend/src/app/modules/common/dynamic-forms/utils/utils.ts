import { IFormModelChanges } from "../typings";

export function mergeFormModels(
  defaultModel: IFormModelChanges,
  updateModel: IFormModelChanges
) {
  const { _links: currentResources, ...currentOtherChanges } =
    defaultModel || {};
  const { _links: formResources, ...formOtherChanges } = updateModel;
  const mergeFormModelChanges = {
    ...currentOtherChanges,
    ...formOtherChanges,
    ...((currentResources || formResources) && {
      _links: {
        ...currentResources,
        ...formResources
      }
    })
  };

  return mergeFormModelChanges;
}
