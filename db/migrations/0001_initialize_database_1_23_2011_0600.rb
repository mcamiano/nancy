# See http://sequel.rubyforge.org/rdoc/files/doc/migration_rdoc.html
#
# Create a table
migration "Create foos" do
  database.create_table :foos do
    primary_key :id
    String      :slug_name, :size=>50
    String      :description, :size=>120
    integer     :slug_count, :default => 0
    timestamp   :created, :null => false

    index :slug_name, :unique => true
  end
end

__END__
Data Types: lowercase method, symbol, or string type names will not be translated
Otherwise, the Sequel create_table Ruby type equivalencies are:
      primary_key :id, :type=>Integer             # integer
      String :a                                   # varchar(255)
      String :a2, :size=>50                       # varchar(50)
      String :a3, :fixed=>true                    # char(255)
      String :a4, :fixed=>true, :size=>50         # char(50)
      String :a5, :text=>true                     # text
      column :b, File                             # blob
      Fixnum :c                                   # integer
      foreign_key :d, :other_table, :type=>Bignum # bigint
      Float :e                                    # double precision
      BigDecimal :f                               # numeric
      BigDecimal :f2, :size=>10                   # numeric(10)
      BigDecimal :f3, :size=>[10, 2]              # numeric(10, 2)
      Date :g                                     # date
      DateTime :h                                 # timestamp
      Time :i                                     # timestamp
      Time :i2, :only_time=>true                  # time
      Numeric :j                                  # numeric
      TrueClass :k                                # boolean
      FalseClass :l                               # boolean
