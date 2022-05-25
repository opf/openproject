export function bootstrapTurboFrames():void {
  document.addEventListener('turbo:frame-render', async (event) => {
    const context = await window.OpenProject.getPluginContext();
    context.bootstrap(event.target as HTMLElement);
  });
}
