module SQLHelper
  def self.db
    @db ||= Database.connection
  end

  def self.build_update_set(fields, allowed_fields)
    set_fragments = []
    values = []

    fields.each_with_index do |(key, value), index|
      next unless allowed_fields.include?(key)
      set_fragments << "#{key} = $#{index + 1}"
      values << value
    end

    [set_fragments.join(", "), values]
  end

  def self.create(table, fields, allowed_fields)
    normalized_fields = fields.transform_keys(&:to_s)
    filtered_fields = normalized_fields.select { |k, _| allowed_fields.include?(k) }
    keys = filtered_fields.keys
    values = filtered_fields.values
    placeholders = keys.each_index.map { |i| "$#{i + 1}" }

    sql = <<~SQL
      INSERT INTO #{table} (#{keys.join(", ")})
      VALUES (#{placeholders.join(", ")})
      RETURNING *
    SQL

    res = db.exec_params(sql, values)
    res.first
  end
  
  def self.update(table, id, fields, allowed_fields)
    return find_by_id(table, id) if fields.empty?

    set_clause, values = build_update_set(fields, allowed_fields)
    sql = <<~SQL
      UPDATE #{table}
      SET #{set_clause}, updated_at = NOW()
      WHERE id = $#{values.size + 1}
      RETURNING *
    SQL

    values << id
    res = db.exec_params(sql, values)
    res.first
  end

  def self.update_column(table, column, value, conditions)
    condition_sql = conditions.keys.each_with_index.map { |k, i| "#{k} = $#{i + 2}" }.join(" AND ")
    sql = "UPDATE #{table} SET #{column} = $1, updated_at = NOW() WHERE #{condition_sql}"
    values = [value] + conditions.values
    db.exec_params(sql, values)
  end

  def self.find_by(table, field, value)
    sql = "SELECT * FROM #{table} WHERE #{field} = $1 LIMIT 1"
    db.exec_params(sql, [value]).first
  end

  def self.find_by_id(table, id)
    res = db.exec_params("SELECT * FROM #{table} WHERE id = $1", [id])
    res.first
  end

  def self.delete(table, id)
    db.exec_params("DELETE FROM #{table} WHERE id = $1", [id])
  end
end
