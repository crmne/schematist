# Release process

1. Bump the version in `lib/schematist/version.rb`
2. Run `bundle install`
3. Write the release notes in `packaging/release-notes/vX.Y.Z.md`
4. Commit the changes with a message like "Bump version to X.Y.Z"
5. Run `bundle exec rake release:prepare`
6. Push to `main`
7. GitHub Actions will publish the gem if the version is not already on RubyGems
8. GitHub Actions will create the `vX.Y.Z` tag and a GitHub Release whose description is
   `packaging/release-notes/vX.Y.Z.md`, if they do not already exist

Note that step 7 fires on any change to `lib/schematist/version.rb`, so a version bump on `main`
is a release. Hold the bump until everything else for that release has landed.

If the notes file is missing, the release gate fails before anything is published. Pushing the
notes file reruns it and completes the release.

## The ruby_llm-schema compatibility gem

`compat/ruby_llm-schema` is the final release of the old name. It depends on `schematist ~> 1.0`
and aliases `RubyLLM::Schema`, so anyone still on it picks up every schematist 1.x release from a
normal `bundle update`. It does not need a release of its own when schematist ships a new minor,
and it should not get one: releasing a deprecated gem on a schedule makes it look maintained.

It publishes from CI like schematist does, in a job that runs after schematist so the dependency
resolves. The version lives in `compat/ruby_llm-schema/ruby_llm-schema.gemspec`, and the job is a
no-op once that version is on RubyGems. To release it by hand instead:

```bash
cd compat/ruby_llm-schema
gem build ruby_llm-schema.gemspec
gem push ruby_llm-schema-1.0.0.gem
```

Revisit at schematist 2.0. `~> 1.0` will freeze those users on 1.x, so that is the point to
either cut a compatibility 2.0 or let the old name go.
