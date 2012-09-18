class Upsert
  module ActiveRecordUpsert
    def upsert(selector, document = {})
      ActiveRecord::Base.connection_pool.with_connection do |c|
        upsert = Upsert.new c, table_name
        upsert.row selector, document
      end
    end

    def upsert_hash(hash)
      hash = hash.stringify_keys
      selector_keys = upsert_find_longest_unique_fields(hash.keys)
      document_keys = hash.keys - selector_keys
      upsert(hash.slice(*selector_keys), hash.slice(*document_keys))
    end

  private
    def upsert_find_longest_unique_fields(keys)
      found_keys = []
      if upsert_unique_fields.present?
        upsert_unique_fields.select do |uf|
          uf.all?{|d| keys.include?(d)}
        end.sort_by {|a,b| a.size <=> b.size}.last
      else
        keys
      end
    end

    def upsert_unique_fields
      unique_indexes = ActiveRecord::Base.connection.indexes(table_name).select do |index|
        index.unique == true
      end.map do |index|
        index.columns
      end
      unique_indexes
    end
  end
end

ActiveRecord::Base.extend Upsert::ActiveRecordUpsert
