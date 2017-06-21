require 'rom/associations/many_to_one'
require 'rom/sql/associations/core'

module ROM
  module SQL
    module Associations
      class ManyToOne < ROM::Associations::ManyToOne
        include Associations::Core

        # @api public
        def call(target: self.target, preload: false)
          if preload
            schema = target.schema.qualified
            relation = target
          else
            right = source

            target_pk = target.schema.primary_key_name
            right_fk = target.foreign_key(source.name)

            target_schema = target.schema
            right_schema = right.schema.project_pk

            schema =
              if target.schema.key?(right_fk)
                target_schema
              else
                target_schema.merge(right_schema.project_fk(target_pk => right_fk))
              end.qualified

            relation = target.join(source_table, join_keys)
          end

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def join(type, source = self.source, target = self.target)
          source.__send__(type, target.name.dataset, join_keys).qualified
        end

        # @api public
        def join_keys
          with_keys { |source_key, target_key|
            { source[source_key].qualified(source_alias) => target[target_key].qualified }
          }
        end

        # @api public
        def foreign_key
          definition.options[:foreign_key] || source.foreign_key(target.name)
        end

        # @api private
        def prepare(target)
          call(target: target, preload: true)
        end

        protected

        # @api private
        def source_table
          self_ref? ? Sequel.as(source.name.dataset, source_alias) : source.name.dataset
        end

        # @api private
        def source_alias
          self_ref? ? :"#{source.name.dataset.to_s[0]}_0" : source.name.dataset
        end
      end
    end
  end
end