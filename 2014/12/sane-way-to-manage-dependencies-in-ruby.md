Sane way to manage dependencies in Ruby
=======================================
December 15, 2014

I still don't know what's the proper way to deal with dependencies with
Ruby. I've spent a few hours searching, but I don't see any kind of
agreement between Rubyists for this.

A lot agree that Bundler is the right way to go, but the default
configuration is still installing dependencies globally, and it quickly
makes conflicts between different Ruby projects.

I'm used to PHP and Node.js environments, where dependencies are simply
managed *per project*, in a `vendor` or `node_modules` directory. This
way, dependencies are contained in the project, there's no conflict
across projects, and it's easy to bundle them! Why don't Ruby or Python
do this way?

Anyway, I managed to achieve a similar behavior with Bundler. The key is
the `.bundle/config` file, that needs to be copied in every project:

```yaml
BUNDLE_PATH: vendor
```

Then, `bundle install` will create the `vendor` directory, with
contained dependencies. You now need to run all your commands with
`bundle exec` so the Ruby environments is set properly to find
dependencies in the `vendor` directory.
