require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
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
  # Phase IIIb
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
end

class SQLObject
  extend Associatable
end
