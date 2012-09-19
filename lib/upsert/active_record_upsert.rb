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

    def upsert_array(array)
      if array.first && array.first.is_a?(Hash)
        hash_keys = array.first.stringify_keys.keys
        selector_keys = upsert_find_longest_unique_fields(hash_keys)
        document_keys = hash_keys - selector_keys
        ActiveRecord::Base.connection_pool.with_connection do |c|
          upsert = Upsert.new c, table_name
          array.each do |hash|
            upsert.row(hash.stringify_keys.slice(*selector_keys), hash.stringify_keys.slice(*document_keys))
          end
        end
      end
    end

  private
    def upsert_find_longest_unique_fields(keys)
      found_keys = []
      if upsert_unique_fields.present?
        upsert_unique_fields.select do |uf|
          uf.all?{ |d| keys.include?(d) }
        end.sort {|a,b| a.size <=> b.size}.last
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
