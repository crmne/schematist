# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "instance methods" do
  include SchemaBuilders

  let(:schema_class) { build_schema_class }

  it "handles naming correctly" do
    stub_const("TestSchemaClass", build_schema_class)
    expect(TestSchemaClass.new.to_json_schema["title"]).to eq("TestSchemaClass")

    expect(schema_class.new.to_json_schema["title"]).to eq("Schema")
    expect(schema_class.new("CustomName").to_json_schema["title"]).to eq("CustomName")

    described_output = schema_class.new("TestName", description: "Custom description").to_json_schema
    expect(described_output["title"]).to eq("TestName")
    expect(described_output["description"]).to eq("Custom description")
  end

  it "allows configuring the schema name via the DSL" do
    configured_schema = build_schema_class do
      name "ConfiguredDSLName"
    end

    expect(configured_schema.new.to_json_schema["title"]).to eq("ConfiguredDSLName")
  end

  it "supports method delegation for schema methods" do
    instance = schema_class.new

    expect(instance).to respond_to(
      :string, :number, :integer, :boolean, :array, :object, :any_of, :one_of, :null
    )
    expect(instance).not_to respond_to(:unknown_method)
  end

  it "produces correctly structured JSON schema and JSON output" do
    schema_with_fields = build_schema_class do
      string :name
      integer :age, required: false
    end

    json_output = schema_with_fields.new("TestSchema").to_json_schema

    expect(json_output).to include(
      "title" => "TestSchema",
      "type" => "object",
      "properties" => {
        "name" => {"type" => "string"},
        "age" => {"type" => "integer"}
      },
      "required" => ["name"],
      "additionalProperties" => false
    )
    expect(json_output).not_to have_key("description")

    json_string = schema_with_fields.new("TestSchema").to_json
    expect(json_string).to be_a(String)
    expect(JSON.parse(json_string)["title"]).to eq("TestSchema")
  end
end
