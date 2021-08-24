/**
 * Returns an absolute asset path from the assets/images/ folder
 *
 * e.g., to access:
 * frontend/src/assets/images/board_creation_modal/assignees.svg
 *
 * use
 * imagePath('board_creation_modal/assignees.svg')
 *
 *
 * @param image Path to the image starting from frontend/src/assets/images
 */
export function imagePath(image:string) {
  return `${__webpack_public_path__}assets/images/${image}`;
}
