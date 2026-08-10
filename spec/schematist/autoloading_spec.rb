# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist, "autoloading" do
  it "eager loads without a naming mismatch" do
    expect { Zeitwerk::Loader.eager_load_all }.not_to raise_error
  end

  it "resolves every constant from its own path" do
    expect(Schematist::Schema).to be_a(Class)
    expect(Schematist::DSL).to be_a(Module)
    expect(Schematist::DSL::SchemaBuilders).to be_a(Module)
    expect(Schematist::DSL::ConditionalBuilder).to be_a(Class)
    expect(Schematist::DSL::ConditionalContext).to be_a(Class)
    expect(Schematist::Validator).to be_a(Class)
    expect(Schematist::JsonOutput).to be_a(Module)
    expect(Schematist::Helpers).to be_a(Module)
  end

  it "loads the version without loading the gem" do
    expect(Schematist::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end
end
