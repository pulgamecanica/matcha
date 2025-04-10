module SQLHelper
  def self.db
    @db ||= Database.connection
  end

  def self.singularize(word)
    return word if word.end_with?("ss")
    word.sub(/s$/, '')
  end

  def self.pluralize(word)
    return word if word.end_with?("s")
    word + "s"
  end

  def self.table_exists?(table)
    sql = "SELECT to_regclass($1) IS NOT NULL AS exists"
    result = db.exec_params(sql, [table])
    result&.first["exists"] == "t"
  end

  def self.build_update_set(fields, allowed_fields)
    set_fragments = []
    values = []
    
    normalized_fields = fields.transform_keys(&:to_s)
    
    normalized_fields.each_with_index do |(key, value), index|
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
    res&.first
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
    res&.first
  end

  def self.update_column(table, column, value, conditions)
    condition_sql = conditions.keys.each_with_index.map { |k, i| "#{k} = $#{i + 2}" }.join(" AND ")
    sql = "UPDATE #{table} SET #{column} = $1, updated_at = NOW() WHERE #{condition_sql}"
    values = [value] + conditions.values
    db.exec_params(sql, values)
  end

  def self.find_by(table, field, value)
    sql = "SELECT * FROM #{table} WHERE #{field} = $1 LIMIT 1"
    db.exec_params(sql, [value])&.first
  end

  def self.find_by_id(table, id)
    res = db.exec_params("SELECT * FROM #{table} WHERE id = $1", [id])
    res&.first
  end

  def self.find_many_by_ids(table, ids)
    return [] if ids.empty?

    placeholders = ids.each_index.map { |i| "$#{i + 1}" }.join(", ")
    sql = "SELECT * FROM #{table} WHERE id IN (#{placeholders})"

    res = db.exec_params(sql, ids)
    res.to_a
  end

  def self.delete(table, id)
    db.exec_params("DELETE FROM #{table} WHERE id = $1", [id])
  end

  def self.many_to_many(source_sym, target_sym, source_id)
    source      = source_sym.to_s
    target      = target_sym.to_s
    join_table  = "#{source}_#{target}"
    join_table  = "#{target}_#{source}" unless table_exists?(join_table)

    source_id_column = "#{source}_id"
    target_id_column = "#{singularize(target)}_id"

    sql = <<~SQL
      SELECT #{target}.* FROM #{target}
      JOIN #{join_table} ON #{join_table}.#{target_id_column} = #{target}.id
      WHERE #{join_table}.#{source_id_column} = $1
    SQL

    db.exec_params(sql, [source_id]).to_a
  end
end
