require 'ostruct'

module DeveloperProjectsAssociationExtension2
  def find_least_recent
    order("id ASC").first
  end
end

class Developer < ActiveRecord4116::Base
  has_and_belongs_to_many :projects do
    def find_most_recent
      order("id DESC").first
    end
  end

  accepts_nested_attributes_for :projects

  has_and_belongs_to_many :projects_extended_by_name,
      -> { extending(DeveloperProjectsAssociationExtension) },
      :class_name => "Project",
      :join_table => "developers_projects",
      :association_foreign_key => "project_id"

  has_and_belongs_to_many :projects_extended_by_name_twice,
      -> { extending(DeveloperProjectsAssociationExtension, DeveloperProjectsAssociationExtension2) },
      :class_name => "Project",
      :join_table => "developers_projects",
      :association_foreign_key => "project_id"

  has_and_belongs_to_many :projects_extended_by_name_and_block,
      -> { extending(DeveloperProjectsAssociationExtension) },
      :class_name => "Project",
      :join_table => "developers_projects",
      :association_foreign_key => "project_id" do
        def find_least_recent
          order("id ASC").first
        end
      end

  has_and_belongs_to_many :special_projects, :join_table => 'developers_projects', :association_foreign_key => 'project_id'
  has_and_belongs_to_many :sym_special_projects,
                          :join_table => :developers_projects,
                          :association_foreign_key => 'project_id',
                          :class_name => 'SpecialProject'

  has_many :audit_logs
  has_many :contracts
  has_many :firms, :through => :contracts, :source => :firm
  has_many :comments, ->(developer) { where(body: "I'm #{developer.name}") }
  has_many :ratings, through: :comments

  scope :jamises, -> { where(:name => 'Jamis') }

  validates_inclusion_of :salary, :in => 50000..200000
  validates_length_of    :name, :within => 3..20

  before_create do |developer|
    developer.audit_logs.build :message => "Computer created"
  end

  def log=(message)
    audit_logs.build :message => message
  end

  after_find :track_instance_count
  cattr_accessor :instance_count

  def track_instance_count
    self.class.instance_count ||= 0
    self.class.instance_count += 1
  end
  private :track_instance_count

end

class AuditLog < ActiveRecord4116::Base
  belongs_to :developer, :validate => true
  belongs_to :unvalidated_developer, :class_name => 'Developer'
end

DeveloperSalary = Struct.new(:amount)
class DeveloperWithAggregate < ActiveRecord4116::Base
  self.table_name = 'developers'
  composed_of :salary, :class_name => 'DeveloperSalary', :mapping => [%w(salary amount)]
end

class DeveloperWithBeforeDestroyRaise < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, :join_table => 'developers_projects', :foreign_key => 'developer_id'
  before_destroy :raise_if_projects_empty!

  def raise_if_projects_empty!
    raise if projects.empty?
  end
end

class DeveloperWithSelect < ActiveRecord4116::Base
  self.table_name = 'developers'
  default_scope { select('name') }
end

class DeveloperWithIncludes < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_many :audit_logs, :foreign_key => :developer_id
  default_scope { includes(:audit_logs) }
end

class DeveloperFilteredOnJoins < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, -> { order('projects.id') }, :foreign_key => 'developer_id', :join_table => 'developers_projects'

  def self.default_scope
    joins(:projects).where(:projects => { :name => 'Active Controller' })
  end
end

class DeveloperOrderedBySalary < ActiveRecord4116::Base
  self.table_name = 'developers'
  default_scope { order('salary DESC') }

  scope :by_name, -> { order('name DESC') }
end

class DeveloperCalledDavid < ActiveRecord4116::Base
  self.table_name = 'developers'
  default_scope { where("name = 'David'") }
end

class LazyLambdaDeveloperCalledDavid < ActiveRecord4116::Base
  self.table_name = 'developers'
  default_scope lambda { where(:name => 'David') }
end

class LazyBlockDeveloperCalledDavid < ActiveRecord4116::Base
  self.table_name = 'developers'
  default_scope { where(:name => 'David') }
end

class CallableDeveloperCalledDavid < ActiveRecord4116::Base
  self.table_name = 'developers'
  default_scope OpenStruct.new(:call => where(:name => 'David'))
end

class ClassMethodDeveloperCalledDavid < ActiveRecord4116::Base
  self.table_name = 'developers'

  def self.default_scope
    where(:name => 'David')
  end
end

class ClassMethodReferencingScopeDeveloperCalledDavid < ActiveRecord4116::Base
  self.table_name = 'developers'
  scope :david, -> { where(:name => 'David') }

  def self.default_scope
    david
  end
end

class LazyBlockReferencingScopeDeveloperCalledDavid < ActiveRecord4116::Base
  self.table_name = 'developers'
  scope :david, -> { where(:name => 'David') }
  default_scope { david }
end

class DeveloperCalledJamis < ActiveRecord4116::Base
  self.table_name = 'developers'

  default_scope { where(:name => 'Jamis') }
  scope :poor, -> { where('salary < 150000') }
  scope :david, -> { where name: "David" }
  scope :david2, -> { unscoped.where name: "David" }
end

class PoorDeveloperCalledJamis < ActiveRecord4116::Base
  self.table_name = 'developers'

  default_scope -> { where(:name => 'Jamis', :salary => 50000) }
end

class InheritedPoorDeveloperCalledJamis < DeveloperCalledJamis
  self.table_name = 'developers'

  default_scope -> { where(:salary => 50000) }
end

class MultiplePoorDeveloperCalledJamis < ActiveRecord4116::Base
  self.table_name = 'developers'

  default_scope -> { where(:name => 'Jamis') }
  default_scope -> { where(:salary => 50000) }
end

module SalaryDefaultScope
  extend ActiveSupport::Concern

  included { default_scope { where(:salary => 50000) } }
end

class ModuleIncludedPoorDeveloperCalledJamis < DeveloperCalledJamis
  self.table_name = 'developers'

  include SalaryDefaultScope
end

class EagerDeveloperWithDefaultScope < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, -> { order('projects.id') }, :foreign_key => 'developer_id', :join_table => 'developers_projects'

  default_scope { includes(:projects) }
end

class EagerDeveloperWithClassMethodDefaultScope < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, -> { order('projects.id') }, :foreign_key => 'developer_id', :join_table => 'developers_projects'

  def self.default_scope
    includes(:projects)
  end
end

class EagerDeveloperWithLambdaDefaultScope < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, -> { order('projects.id') }, :foreign_key => 'developer_id', :join_table => 'developers_projects'

  default_scope lambda { includes(:projects) }
end

class EagerDeveloperWithBlockDefaultScope < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, -> { order('projects.id') }, :foreign_key => 'developer_id', :join_table => 'developers_projects'

  default_scope { includes(:projects) }
end

class EagerDeveloperWithCallableDefaultScope < ActiveRecord4116::Base
  self.table_name = 'developers'
  has_and_belongs_to_many :projects, -> { order('projects.id') }, :foreign_key => 'developer_id', :join_table => 'developers_projects'

  default_scope OpenStruct.new(:call => includes(:projects))
end

class ThreadsafeDeveloper < ActiveRecord4116::Base
  self.table_name = 'developers'

  def self.default_scope
    sleep 0.05 if Thread.current[:long_default_scope]
    limit(1)
  end
end

class CachedDeveloper < ActiveRecord4116::Base
  self.table_name = "developers"
  self.cache_timestamp_format = :number
end
