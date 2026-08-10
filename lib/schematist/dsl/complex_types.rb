# frozen_string_literal: true

module Schematist
  class Schema
    module DSL
      module ComplexTypes
        def object(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, object_schema(description: description, **options, &block), required: required, requires: requires)
        end

        def array(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, array_schema(description: description, **options, &block), required: required, requires: requires)
        end

        def tuple(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, tuple_schema(description: description, **options, &block), required: required, requires: requires)
        end

        def any_of(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, any_of_schema(description: description, **options, &block), required: required, requires: requires)
        end

        def one_of(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, one_of_schema(description: description, **options, &block), required: required, requires: requires)
        end

        def all_of(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, all_of_schema(description: description, **options, &block), required: required, requires: requires)
        end

        def none_of(name, description: nil, required: true, requires: nil, **options, &block)
          add_property(name, none_of_schema(description: description, **options, &block), required: required, requires: requires)
        end

        # Emits a schema fragment verbatim, for the corners of JSON Schema this DSL does not cover
        def raw(name, schema, required: true, requires: nil)
          add_property(name, schema, required: required, requires: requires)
        end

        def optional(name, description: nil, &block)
          any_of(name, description: description) do
            instance_eval(&block)
            null
          end
        end
      end
    end
  end
end
