require 'dm-core'

module DataMapper
  module Timestamps
    TIMESTAMP_PROPERTIES = {
      :updated_at => [ DateTime, lambda { |r| DateTime.now                             } ],
      :updated_on => [ Date,     lambda { |r| Date.today                               } ],
      :created_at => [ DateTime, lambda { |r| r.created_at || (DateTime.now if r.new?) } ],
      :created_on => [ Date,     lambda { |r| r.created_on || (Date.today   if r.new?) } ],
    }.freeze

    def self.included(model)
      model.before :save, :set_timestamps_on_save
      model.extend ClassMethods
    end

    # Saves the record with the updated_at/on attributes set to the current time.
    def touch
      set_timestamps
      save
    end

    private

    def set_timestamps_on_save
      return unless dirty?
      set_timestamps
    end

    def set_timestamps
      TIMESTAMP_PROPERTIES.each do |name,(_type,proc)|
        if properties.named?(name)
          attribute_set(name, proc.call(self))
        end
      end
    end

    module ClassMethods
      def timestamps(*names)
        raise ArgumentError, 'You need to pass at least one argument' if names.empty?

        names.each do |name|
          case name
            when *TIMESTAMP_PROPERTIES.keys
              options = { :required => true }

              if Property.accepted_options.include?(:auto_validation)
                options.update(:auto_validation => false)
              end

              property name, TIMESTAMP_PROPERTIES[name].first, options
            when :at
              timestamps(:created_at, :updated_at)
            when :on
              timestamps(:created_on, :updated_on)
            else
              raise InvalidTimestampName, "Invalid timestamp property name '#{name}'"
          end
        end
      end
    end # module ClassMethods

    class InvalidTimestampName < RuntimeError; end

    Model.append_inclusions self
  end # module Timestamp

  # include Timestamp or Timestamps, it still works
  Timestamp = Timestamps
end # module DataMapper
