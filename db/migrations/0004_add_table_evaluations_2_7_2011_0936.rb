# add Evaluations table 
migration "Add evaluations table" do
  database.create_table :evaluations do
    primary_key :id
    String :institution, :size=>35, :null=>false
    String :pad, :size=>60, :null=>false
    Integer :year, :default => Time.now.year
    String :semester, :null=>false
    String :course_section, :size=>10 , :null=>false
    String :grade_expected, :size=>1
    text :answers, :size=>1024
    DateTime :created
  end
end

