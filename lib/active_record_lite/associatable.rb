require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader(
    :other_class_name,
    :foreign_key,
    :primary_key
  )

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelize
    @foreign_key = params[:foreign_key] || (name.to_s + "_id")
    @primary_key = params[:primary_key] || "id"
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    define_method(name.to_sym) do
      results = DBConnection.execute(<<-SQL, self.send(aps.foreign_key))
        SELECT
          *
        FROM
          #{aps.other_table}
        WHERE
          #{aps.other_table}.#{aps.primary_key} = ?
      SQL

      aps.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
  end

  def has_one_through(name, assoc1, assoc2)
  end
end
