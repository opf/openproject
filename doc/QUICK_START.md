<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2015 the OpenProject Foundation (OPF)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 3.

OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
Copyright (C) 2006-2013 Jean-Philippe Lang
Copyright (C) 2010-2013 the ChiliProject Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

See doc/COPYRIGHT.rdoc for more details.

++-->

# Quick Start for Developers


Detailed installation instructions for different platforms are located on the [OpenProject website](https://www.openproject.org/download/).

You can find information on configuring OpenProject in [`config/CONFIGURATION.md`](CONFIGURATION.md).

## Fast install

These are generic (and condensed) installation instructions for the **current dev** branch *without plugins*, and optimised for a development environment. Refer to the OpenProject website for instructions for the **stable** branch, OpenProject configurations with plugins, as well as platform-specific guides.

### Prerequisites

* Git
* Database (MySQL 5.x/PostgreSQL 8.x)
* Ruby 2.1.x
* Node.js (version v0.10.x)
* Bundler (version 1.5.1 or higher required)

### Install Dependencies

1. Install Ruby dependencies with Bundler:

        bundle install

2. Install JavaScript dependencies with [npm]:

        npm install

3. Install `foreman` gem:

        [sudo] gem install foreman

### Configure Rails

1. Copy `config/database.yml.example` to `config/database.yml`:

        cd config
        cp database.yml.example database.yml

   Edit `database.yml` according to your preferred database's settings.

2. Copy `config/configuration.yml.example` to `config/configuration.yml`:

        cp configuration.yml.example configuration.yml
        cd ..

   Edit `configuration.yml` according to your preferred settings for email, etc. (see [`config/CONFIGURATION.md`](CONFIGURATION.md) for a full list of configuration options).

3. Create databases, schemas and populate with seed data:

        # bundle exec rake db:create:all
        # bundle exec rake db:migrate
        # bundle exec rake db:seed

4. Generate a secret token for the session store:

        bundle exec rake generate_secret_token

### Run!

1. Start OpenProject in development mode:

        foreman start -f Procfile.dev

   The application will be available at `http://127.0.0.1:5000`. To customize
   bind address and port copy the `.env.sample` provided in the root of this
   project as `.env` and [configure values][foreman-env] as required.

   By default a worker process will also be started. In development asynchronous
   execution of long-running background tasks (sending emails, copying projects,
   etc.) may be of limited use. To disable the worker process:

        echo "concurrency: web=1,assets=1,worker=0" >> .foreman

   For more information refer to Foreman documentation section on [default options][foreman-defaults].

[Node.js]:http://nodejs.org/
[Bundler]:http://bundler.io/
[npm]:https://www.npmjs.org/
[Bower]:http://bower.io/
[foreman-defaults]:http://ddollar.github.io/foreman/#DEFAULT-OPTIONS
[foreman-env]:http://ddollar.github.io/foreman/#ENVIRONMENT
