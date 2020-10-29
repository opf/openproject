# Contributing

We love pull requests from everyone. By participating in this project, you
agree to abide by the [code of conduct](https://github.com/kpumuk/meta-tags/blob/master/CODE_OF_CONDUCT.md).

## Configuring Development Environment

Fork, then clone the repo:

    git clone git@github.com:your-username/meta-tags.git

Set up your machine:

    ./bin/setup

Make sure the tests pass:

    rake

## Contributing a Code Change

Make your change. Add tests for your change. Make the tests pass:

    rake

## Fixing a Meta Tag to Use `property` Argument

[HTML standard](https://www.w3schools.com/TAgs/tag_meta.asp) states that the
argument for the meta tag name should be `name`:

```html
<meta name="keywords" content="HTML,CSS,XML,JavaScript">
```

Some social networks require to use `property` argument instead (Facebook Open Graph).
MetaTags supports the most popular meta tags, but there will be tags that are not covered
by default. If you found one, and you feel like the community would benefit from
MetaTags supporting it out of the box, feel free to add it to [the list](https://github.com/kpumuk/meta-tags/blob/master/lib/meta_tags/configuration.rb#L23-L57)
and submit a pull request.

## Raising a Pull Request

Push to your fork and [submit a pull request](https://github.com/kpumuk/meta-tags/compare/).

At this point you're waiting on us. We like to at least comment on pull requests
within couple days. We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted:

* Write tests.
* Make sure [CodeClimate](https://codeclimate.com/github/kpumuk/meta-tags/builds) build is clean.
* Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).
