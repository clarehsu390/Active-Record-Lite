require_relative 'db_connection'
require 'active_support/inflector'
require_relative '02_searchable.rb'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    col = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      LIMIT
       0
    SQL
    @columns = col.flatten.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end
      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
    finalize!

  end

  def self.table_name
    @table_name || self.name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
     parse_all(results)
  end

  def self.parse_all(results)
    results.map { |el| self.new(el)}

  end

  def self.find(id)
    results = DBConnection.execute2(<<-SQL, id)
      SELECT
        *
      FROM
       "#{table_name}"
      WHERE
        "#{table_name}".id = ?
      SQL
    parse_all(results)[1]
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      name = attr_name.to_sym
      if self.class.columns.include?(name)
        self.send("#{name}=", value)
      else
        raise "unknown attribute '#{name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}

  end

  def attribute_values
    self.class.columns.map { |name| self.send(name) }
  end

  def insert
    columns = self.class.columns
    col_names = columns.join(", ")
    question_marks = ["?"] * columns.length

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name}(#{col_names})
      VALUES
        (#{question_marks.join(",")})
    SQL
      self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns
    set_line = columns.map {|column| "#{column} = ?"}
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line.join(", ")}
      WHERE
        #{self.class.table_name}.id = ?
      SQL
  end

  def save
    insert if id.nil?
    update
  end
end
