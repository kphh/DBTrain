require_relative './db_connection'
require 'debugger'

module Searchable
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