# frozen_string_literal: true

require "spec_helper"
require "open3"

# The final ruby_llm-schema release aliases RubyLLM::Schema to Schematist::Schema. It is
# loaded in a subprocess so `require "ruby_llm/schema"` is exercised the way a consumer
# would, and so its constants do not leak into the rest of the suite.
RSpec.describe Schematist, "ruby_llm-schema compatibility alias" do
  def load_alias(body)
    compat = File.expand_path("../../compat/ruby_llm-schema/lib", __dir__)
    lib = File.expand_path("../../lib", __dir__)
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby, "-I#{lib}", "-I#{compat}", "-e", %(require "ruby_llm/schema"\n#{body})
    )
    raise "subprocess failed: #{stderr}" unless status.success?

    [stdout.strip, stderr]
  end

  it "aliases the schema class to Schematist::Schema" do
    out, = load_alias('puts RubyLLM::Schema.equal?(Schematist::Schema)')

    expect(out).to eq("true")
  end

  it "aliases the helpers module" do
    out, = load_alias('puts RubyLLM::Helpers.equal?(Schematist::Helpers)')

    expect(out).to eq("true")
  end

  it "keeps the old error constants resolvable" do
    out, = load_alias('puts RubyLLM::Schema::ValidationError.equal?(Schematist::ValidationError)')

    expect(out).to eq("true")
  end

  it "still builds a working schema through the old constant" do
    out, = load_alias(<<~RUBY)
      klass = Class.new(RubyLLM::Schema) { string :name }
      puts klass.new("Person").to_json_schema["properties"].keys.inspect
    RUBY

    expect(out).to eq('["name"]')
  end

  it "warns that the gem was renamed" do
    _, stderr = load_alias("")

    expect(stderr).to include("ruby_llm-schema is now schematist")
  end
end
