require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{@table_name}
    SQL

    parse_all(rows)
  end

  def self.find(id)
    item = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      id = #{id}
    SQL

    parse_all(item).first
  end

  def create
    #send each attribute to get values
    attr_string = self.class.attributes.join(", ")
    quest_string = (['?'] * self.class.attributes.count).join(", ")
    #insert into table name
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
    #{self.class.table_name}
    (#{attr_string})
    VALUES
    (#{quest_string})
    SQL

    self.id = DBConnection.last_insert_row_id

    nil
  end


  def update
    set_string = (self.class.attributes.map { |attr| "#{attr} = ?" }).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
    UPDATE
    #{self.class.table_name}
    SET
    #{set_string}
    WHERE
    id = #{self.id}
    SQL
  end

  def save
    self.id.nil? ? create : update
  end

  def attribute_values
    self.class.attributes.map do |attr|
      self.send(attr)
    end
  end
end
