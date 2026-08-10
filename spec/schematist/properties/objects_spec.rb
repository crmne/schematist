# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "object properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports object properties with inline attributes" do
    schema_class.object :address do
      string :street
      string :city
      integer :zip_code, required: false
    end

    properties = schema_class.properties
    expect(properties[:address]).to include(
      type: "object",
      properties: {
        street: {type: "string"},
        city: {type: "string"},
        zip_code: {type: "integer"}
      },
      required: %i[street city],
      additionalProperties: false
    )
  end

  context "when referencing another schema" do
    let(:person_schema) do
      Class.new(described_class) do
        string :name, description: "Person's name"
        integer :age, description: "Person's age"
      end
    end

    let(:person_schema_hash) do
      {
        type: "object",
        properties: {
          name: {type: "string", description: "Person's name"},
          age: {type: "integer", description: "Person's age"}
        },
        required: %i[name age],
        additionalProperties: false
      }
    end

    before do
      stub_const("PersonSchema", person_schema)
    end

    it "supports object with of parameter" do
      schema_class.object :founder, of: PersonSchema

      properties = schema_class.properties
      expect(properties[:founder]).to eq(person_schema_hash)
      expect(schema_class.definitions).to be_empty
    end

    it "supports object with of parameter and description" do
      schema_class.object :primary_contact, of: PersonSchema, description: "Main contact person"

      properties = schema_class.properties
      expect(properties[:primary_contact]).to eq(person_schema_hash.merge(description: "Main contact person"))
    end

    it "supports Schema.new inside object block" do
      schema_class.object :founder do
        PersonSchema.new
      end

      properties = schema_class.properties
      expect(properties[:founder]).to eq(person_schema_hash)
      expect(schema_class.definitions).to be_empty
    end

    it "supports Schema.new with description" do
      schema_class.object :ceo, description: "Chief Executive Officer" do
        PersonSchema.new
      end

      properties = schema_class.properties
      expect(properties[:ceo]).to eq(person_schema_hash.merge(description: "Chief Executive Officer"))
    end
  end
end
