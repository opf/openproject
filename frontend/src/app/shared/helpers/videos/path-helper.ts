/**
 * Returns an absolute asset path from the assets/videos/ folder
 *
 * e.g., to access:
 * frontend/src/assets/videos/enterprise/date-alert-notification-settings.mp4
 *
 * use
 * imagePath('enterprise/date-alert-notification-settings.mp4')
 *
 *
 * @param video Path to the video starting from frontend/src/assets/videos
 */
export function videoPath(video:string):string {
  return `${__webpack_public_path__}assets/videos/${video}`;
}
