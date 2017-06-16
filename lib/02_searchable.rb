require_relative 'db_connection'
require_relative '01_sql_object'
require 'active_support/inflector'

module Searchable
  def where(params)
    p where_line = params.keys.map {|key| "#{key} = ?"}.join(" AND ")
    p values = params.values
    result = DBConnection.execute(<<-SQL, values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL
    parse_all(result)
  end
end

class SQLObject
  extend Searchable
end
