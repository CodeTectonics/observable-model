module ObservableModel
  module Sources
    module ActiveRecordObservable
      extend ActiveSupport::Concern

      included do
        attr_accessor :skip_observers

        before_create :pre_create
        before_update :pre_update
        before_destroy :pre_destroy
        after_create_commit :on_create_commit
        after_update_commit :on_update_commit
        after_destroy_commit :on_destroy_commit

        def observer_class_name
          "#{self.class.name}Observer"
        end

        def observer
          observer_class_name.constantize.new(self) unless skip_observers
        end

        delegate :pre_create, to: :observer, allow_nil: true

        delegate :pre_update, to: :observer, allow_nil: true

        delegate :pre_destroy, to: :observer, allow_nil: true

        delegate :on_create_commit, to: :observer, allow_nil: true

        delegate :on_update_commit, to: :observer, allow_nil: true

        delegate :on_destroy_commit, to: :observer, allow_nil: true
      end
    end
  end
end
