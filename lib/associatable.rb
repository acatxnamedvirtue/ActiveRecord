require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end

  def set_defaults(name, self_class_name = nil)
    self.foreign_key ||= self.is_a?(BelongsToOptions) ? "#{name}_id".to_sym : "#{self_class_name.downcase}_id".to_sym
    self.class_name ||= self.is_a?(BelongsToOptions) ? "#{name.to_s.capitalize}" : "#{name.to_s.singularize.capitalize}"
    self.primary_key ||= :id
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options.each { |attr_name, value| self.send("#{attr_name}=",value) }
    set_defaults(name)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options.each { |attr_name, value| self.send("#{attr_name}=",value) }
    set_defaults(name, self_class_name)
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      foreign_key = options.send(:foreign_key)
      target_class = options.model_class
      primary_key = options.send(:primary_key)

      target_class.where(primary_key => self.send(foreign_key)).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, "#{self}", options)

    define_method(name) do
      foreign_key = options.send(:foreign_key)
      target_class = options.model_class
      primary_key = options.send(:primary_key)

      target_class.where(foreign_key => self.send(primary_key))
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      from_table = self.class.table_name
      through_table = through_options.table_name
      source_table = source_options.table_name

      thru_primary_key = through_options.primary_key
      thru_foreign_key = through_options.foreign_key

      source_primary_key = source_options.primary_key
      source_foreign_key = source_options.foreign_key

      results = DBConnection.execute(<<-SQL)
        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{source_table}.#{source_primary_key} =
          #{through_table}.#{source_foreign_key}
        WHERE
          #{through_table}.#{thru_primary_key} = #{self.send(thru_foreign_key)}
      SQL

      source_options.model_class.new(results.first)
    end
  end
end
