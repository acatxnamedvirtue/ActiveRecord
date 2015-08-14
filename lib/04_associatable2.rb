require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

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
