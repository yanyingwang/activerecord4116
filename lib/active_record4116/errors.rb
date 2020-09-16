module ActiveRecord4116

  # = Active Record Errors
  #
  # Generic Active Record exception class.
  class ActiveRecord4116Error < StandardError
  end

  # Raised when the single-table inheritance mechanism fails to locate the subclass
  # (for example due to improper usage of column that +inheritance_column+ points to).
  class SubclassNotFound < ActiveRecord4116Error #:nodoc:
  end

  # Raised when an object assigned to an association has an incorrect type.
  #
  #   class Ticket < ActiveRecord4116::Base
  #     has_many :patches
  #   end
  #
  #   class Patch < ActiveRecord4116::Base
  #     belongs_to :ticket
  #   end
  #
  #   # Comments are not patches, this assignment raises AssociationTypeMismatch.
  #   @ticket.patches << Comment.new(content: "Please attach tests to your patch.")
  class AssociationTypeMismatch < ActiveRecord4116Error
  end

  # Raised when unserialized object's type mismatches one specified for serializable field.
  class SerializationTypeMismatch < ActiveRecord4116Error
  end

  # Raised when adapter not specified on connection (or configuration file <tt>config/database.yml</tt>
  # misses adapter field).
  class AdapterNotSpecified < ActiveRecord4116Error
  end

  # Raised when Active Record cannot find database adapter specified in <tt>config/database.yml</tt> or programmatically.
  class AdapterNotFound < ActiveRecord4116Error
  end

  # Raised when connection to the database could not been established (for example when <tt>connection=</tt>
  # is given a nil object).
  class ConnectionNotEstablished < ActiveRecord4116Error
  end

  # Raised when Active Record cannot find record by given id or set of ids.
  class RecordNotFound < ActiveRecord4116Error
  end

  # Raised by ActiveRecord4116::Base.save! and ActiveRecord4116::Base.create! methods when record cannot be
  # saved because record is invalid.
  class RecordNotSaved < ActiveRecord4116Error
  end

  # Raised by ActiveRecord4116::Base.destroy! when a call to destroy would return false.
  class RecordNotDestroyed < ActiveRecord4116Error
  end

  # Superclass for all database execution errors.
  #
  # Wraps the underlying database error as +original_exception+.
  class StatementInvalid < ActiveRecord4116Error
    attr_reader :original_exception

    def initialize(message, original_exception = nil)
      super(message)
      @original_exception = original_exception
    end
  end

  # Defunct wrapper class kept for compatibility.
  # +StatementInvalid+ wraps the original exception now.
  class WrappedDatabaseException < StatementInvalid
  end

  # Raised when a record cannot be inserted because it would violate a uniqueness constraint.
  class RecordNotUnique < WrappedDatabaseException
  end

  # Raised when a record cannot be inserted or updated because it references a non-existent record.
  class InvalidForeignKey < WrappedDatabaseException
  end

  # Raised when number of bind variables in statement given to <tt>:condition</tt> key (for example,
  # when using +find+ method)
  # does not match number of expected variables.
  #
  # For example, in
  #
  #   Location.where("lat = ? AND lng = ?", 53.7362)
  #
  # two placeholders are given but only one variable to fill them.
  class PreparedStatementInvalid < ActiveRecord4116Error
  end

  # Raised when a given database does not exist
  class NoDatabaseError < ActiveRecord4116Error
    def initialize(message)
      super extend_message(message)
    end

    # can be over written to add additional error information.
    def extend_message(message)
      message
    end
  end

  # Raised on attempt to save stale record. Record is stale when it's being saved in another query after
  # instantiation, for example, when two users edit the same wiki page and one starts editing and saves
  # the page before the other.
  #
  # Read more about optimistic locking in ActiveRecord4116::Locking module RDoc.
  class StaleObjectError < ActiveRecord4116Error
    attr_reader :record, :attempted_action

    def initialize(record, attempted_action)
      super("Attempted to #{attempted_action} a stale object: #{record.class.name}")
      @record = record
      @attempted_action = attempted_action
    end

  end

  # Raised when association is being configured improperly or
  # user tries to use offset and limit together with has_many or has_and_belongs_to_many associations.
  class ConfigurationError < ActiveRecord4116Error
  end

  # Raised on attempt to update record that is instantiated as read only.
  class ReadOnlyRecord < ActiveRecord4116Error
  end

  # ActiveRecord4116::Transactions::ClassMethods.transaction uses this exception
  # to distinguish a deliberate rollback from other exceptional situations.
  # Normally, raising an exception will cause the +transaction+ method to rollback
  # the database transaction *and* pass on the exception. But if you raise an
  # ActiveRecord4116::Rollback exception, then the database transaction will be rolled back,
  # without passing on the exception.
  #
  # For example, you could do this in your controller to rollback a transaction:
  #
  #   class BooksController < ActionController::Base
  #     def create
  #       Book.transaction do
  #         book = Book.new(params[:book])
  #         book.save!
  #         if today_is_friday?
  #           # The system must fail on Friday so that our support department
  #           # won't be out of job. We silently rollback this transaction
  #           # without telling the user.
  #           raise ActiveRecord4116::Rollback, "Call tech support!"
  #         end
  #       end
  #       # ActiveRecord4116::Rollback is the only exception that won't be passed on
  #       # by ActiveRecord4116::Base.transaction, so this line will still be reached
  #       # even on Friday.
  #       redirect_to root_url
  #     end
  #   end
  class Rollback < ActiveRecord4116Error
  end

  # Raised when attribute has a name reserved by Active Record (when attribute has name of one of Active Record instance methods).
  class DangerousAttributeError < ActiveRecord4116Error
  end

  # Raised when unknown attributes are supplied via mass assignment.
  class UnknownAttributeError < NoMethodError

    attr_reader :record, :attribute

    def initialize(record, attribute)
      @record = record
      @attribute = attribute.to_s
      super("unknown attribute: #{attribute}")
    end

  end

  # Raised when an error occurred while doing a mass assignment to an attribute through the
  # <tt>attributes=</tt> method. The exception has an +attribute+ property that is the name of the
  # offending attribute.
  class AttributeAssignmentError < ActiveRecord4116Error
    attr_reader :exception, :attribute
    def initialize(message, exception, attribute)
      super(message)
      @exception = exception
      @attribute = attribute
    end
  end

  # Raised when there are multiple errors while doing a mass assignment through the +attributes+
  # method. The exception has an +errors+ property that contains an array of AttributeAssignmentError
  # objects, each corresponding to the error while assigning to an attribute.
  class MultiparameterAssignmentErrors < ActiveRecord4116Error
    attr_reader :errors
    def initialize(errors)
      @errors = errors
    end
  end

  # Raised when a primary key is needed, but not specified in the schema or model.
  class UnknownPrimaryKey < ActiveRecord4116Error
    attr_reader :model

    def initialize(model)
      super("Unknown primary key for table #{model.table_name} in model #{model}.")
      @model = model
    end

  end

  # Raised when a relation cannot be mutated because it's already loaded.
  #
  #   class Task < ActiveRecord4116::Base
  #   end
  #
  #   relation = Task.all
  #   relation.loaded? # => true
  #
  #   # Methods which try to mutate a loaded relation fail.
  #   relation.where!(title: 'TODO')  # => ActiveRecord4116::ImmutableRelation
  #   relation.limit!(5)              # => ActiveRecord4116::ImmutableRelation
  class ImmutableRelation < ActiveRecord4116Error
  end

  class TransactionIsolationError < ActiveRecord4116Error
  end
end
