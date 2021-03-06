require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'
require 'debugger'

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
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @foreign_key = params[:foreign_key] || (self_class.to_s.underscore + "_id")
    @primary_key = params[:primary_key] || "id"
  end

  def type
    :has_many
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps

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
    aps = HasManyAssocParams.new(name, params, self)
    assoc_params[name] = aps

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.primary_key))
        SELECT
          *
        FROM
          #{aps.other_table}
        WHERE
          #{aps.other_table}.#{aps.foreign_key} = ?
      SQL

      aps.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      aps1 = self.class.assoc_params[assoc1]
      aps2 = aps1.other_class.assoc_params[assoc2]

      prim_key = self.send(aps1.foreign_key)

      results = DBConnection.execute(<<-SQL, prim_key)
        SELECT
          #{aps2.other_table}.*
        FROM
          #{aps1.other_table}
        JOIN
          #{aps2.other_table}
        ON
          #{aps1.other_table}.#{aps2.foreign_key} =
          #{aps2.other_table}.#{aps2.primary_key}
        WHERE
          #{aps1.other_table}.#{aps1.primary_key} = ?
      SQL

      aps2.other_class.parse_all(results).first
    end
  end
end
