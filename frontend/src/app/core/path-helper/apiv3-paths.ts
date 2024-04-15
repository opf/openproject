import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export class ApiV3Paths {
  readonly apiV3Base:string;

  constructor(basePath:string) {
    this.apiV3Base = `${basePath}/api/v3`;
  }

  public get openApiSpecPath():string {
    return `${this.apiV3Base}/spec.json`;
  }

  /**
   * Preview markup path
   *
   * Primarily used from ckeditor-augmented-textarea
   * https://github.com/opf/commonmark-ckeditor-build/
   *
   * @param context
   */
  public previewMarkup(context:string) {
    const base = `${this.apiV3Base}/render/markdown`;

    if (context) {
      return `${base}?context=${context}`;
    }
    return base;
  }

  /**
   * Principals autocompleter path
   *
   * Primarily used from ckeditor-augmented-textarea
   * https://github.com/opf/commonmark-ckeditor-build/
   *
   */
  public principals(workPackage:WorkPackageResource, term:string|null) {
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    // Only real and activated users:
    filters.add('status', '!', ['3']);

    if (!workPackage.id || workPackage.id === 'new') {
      // that are members of that project:
      filters.add('member', '=', [(workPackage.project as HalResource).id as string]);
    } else {
      // that are mentionable on the work package
      filters.add('mentionable_on_work_package', '=', [workPackage.id.toString()]);
    }
    // That are users:
    filters.add('type', '=', ['User', 'Group']);

    if (term && term.length > 0) {
      // Containing the that substring:
      filters.add('name', '~', [term]);
    }

    return `${this.apiV3Base
    }/principals?${
      filters.toParams({ sortBy: '[["name","asc"]]', offset: '1', pageSize: '10' })}`;
  }
}
