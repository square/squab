require 'sequel'
require 'tempfile'

module TestDBHelper
  def self.teardown(conn)
    db = Sequel.connect(conn)
    if db.database_type == :sqlite
      db_file = db.url.dup
      if db_file.start_with?('sqlite://')
        db_file.sub!(/\Asqlite:\/\//, '')
        if File.exist?(db_file)
          File.unlink(db_file)
        end
      end
    else
      db.drop_table?(:events)
    end
  end

  def self.tmp_db_conn
    temp_file = Tempfile.new("squab-test-db")
    db_conn = "sqlite://" + temp_file.path
  end
end
