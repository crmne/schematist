# ruby_llm-schema (deprecated)

This gem is now [schematist](https://github.com/crmne/schematist). This directory holds the
final `ruby_llm-schema` release, which does nothing but depend on schematist and alias
`RubyLLM::Schema` to `Schematist::Schema`.

It lives in the schematist repo rather than its own, so the alias cannot drift from the gem
it forwards to. The spec suite loads it and checks the aliases still resolve.

## Building and releasing

The root gemspec builds schematist. This one has to be built from this directory:

```bash
cd compat/ruby_llm-schema
gem build ruby_llm-schema.gemspec
gem push ruby_llm-schema-1.0.0.gem
```

schematist 1.0.0 must be on RubyGems first, since this gem depends on it.

The version tracks the schematist release it forwards to.

## What the alias cannot forward

- `strict` was removed. It is an OpenAI `response_format` flag, not a JSON Schema keyword.
- `to_json_schema` returns a Draft 2020-12 document with string keys, not the
  `{name:, description:, schema:}` provider envelope. Build that envelope where you send it.
