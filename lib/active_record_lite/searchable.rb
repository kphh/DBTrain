require_relative './db_connection'
require 'debugger'

module Searchable
  # takes a hash like { :attr_name => :search_val1, :attr_name2 => :search_val2 }
  # map the keys of params to an array of  "#{key} = ?" to go in WHERE clause.
  # Hash#values will be helpful here.
  # returns an array of objects
  def where(params)
    vals = params.values
    set_string = params.map { |k, v| "#{k} = ?" }.join(" AND ")
    results = DBConnection.execute(<<-SQL, *vals)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{set_string}
    SQL

    parse_all(results)
  end
end