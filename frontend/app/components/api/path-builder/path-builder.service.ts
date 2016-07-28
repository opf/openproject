//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

import {opApiModule} from '../../../angular-modules';

/**
 * Allows defining flexible paths using urijs.
 *
 * See the following links for more information on URITemplate and urijs.
 * uirjs: https://medialize.github.io/URI.js/docs.html
 * URITemplates: https://tools.ietf.org/html/rfc6570#section-2.1
 */
export class PathBuilderService {
  constructor(protected URI) {
  }

  /**
   * Return a collection of callable paths.
   *
   * @see path
   * @param templates
   * @return A collection of callable paths
   */
  public buildPaths(templates:any) {
    const pathCollection = {};

    angular.forEach(templates, (template, name) => {
      pathCollection[name] = this.buildPath(template);
    });

    return pathCollection;
  }

  /**
   * Return a callable path, that receives arguments to pass to the URITemplate.
   *
   * @param config: A string or an array where the first argument is the template and the second
   * is config for nested paths.
   * @return A callable path
   */
  protected buildPath(config) {
    const isArray = Array.isArray(config);
    const template = isArray ? config[0] : config;
    const callable = this.getCallable(template);

    if (isArray) {
      angular.forEach(config[1], (config, name) => {
        if (Array.isArray(config)) {
          config[0] = template + '/' + config[0];
        } else {
          config = template + '/' + config;
        }

        callable[name] = this.buildPath(config);
      });
    }

    return callable;
  }

  /**
   * Return a function wrapper for `URI.expand()`.
   *
   * @param template
   * @return {(values?:{})=>boolean|string}
   */
  private getCallable(template:string) {
    return (values = {}) => this.URI.expand(template, values).valueOf();
  }
}

opApiModule.service('pathBuilder', PathBuilderService);
