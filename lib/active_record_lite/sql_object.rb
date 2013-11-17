require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable
  extend Associatable
  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{@table_name}
    SQL

    parse_all(rows)
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
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

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
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

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
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

  # call either create or update depending if id is nil.
  def save
    self.id.nil? ? create : update
  end

  # helper method to return values of the attributes.
  def attribute_values
    self.class.attributes.map do |attr|
      self.send(attr)
    end
  end
end
