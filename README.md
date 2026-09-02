# ObservableModel

A Ruby gem that implements the Observer pattern for ActiveRecord models in Rails applications. ObservableModel provides a clean, organized way to respond to model lifecycle events (create, update, destroy) without cluttering your models with callback logic.

## Why ObservableModel?

As Rails applications grow, model callbacks can become cluttered with business logic, side effects, and external service integrations. ObservableModel helps you:

- **Separate concerns** - Keep models focused on data and validation
- **Organize side effects** - Isolate external service calls, notifications, and async jobs
- **Improve testability** - Easily skip observers in tests with `skip_observers` flag
- **Follow patterns** - Implement the classic Observer pattern in a Rails-friendly way
- **Maintain clarity** - Know exactly where lifecycle-triggered logic lives

## Features

- 🎯 **Simple integration** - Just include a module in your ActiveRecord models
- 🔄 **Lifecycle hooks** - Respond to before and after commit events for create, update, and destroy
- 🚫 **Skippable observers** - Disable observers per-instance when needed
- 🧩 **Convention-based** - Auto-discovers observer classes (e.g., `UserObserver` for `User`)
- ⚡ **Before-commit callbacks** - Enables observer actions to run before changes are committed
- ⚡ **After-commit callbacks** - Ensures database transactions complete before running observer actions
- 🧪 **Test-friendly** - Easy to bypass observers in test scenarios

## Requirements

- Ruby >= 3.2.0
- Rails >= 6.1

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'observable_model'
```

And then execute:

```bash
$ bundle install
```

## Usage

### Basic Setup

1. **Include the module in your ActiveRecord model:**

```ruby
class User < ApplicationRecord
  include ObservableModel::Sources::ActiveRecordObservable
  
  # Your model code...
end
```

2. **Create an observer class:**

ObservableModel uses a naming convention: for a model named `User`, create a `UserObserver` class.

```ruby
# app/observers/user_observer.rb
class UserObserver < ObservableModel::Observers::Base
  def pre_create
    # Called before the record is created
  end

  def pre_update
    # Called before the record is updated
  end

  def pre_destroy
    # Called before the record is destroyed
  end

  def on_create_commit
    # Called after a user is created and committed to the database
    WelcomeMailer.welcome_email(@observable).deliver_later
    AnalyticsService.track_signup(@observable)
  end

  def on_update_commit
    # Called after a user is updated and committed
    if @observable.saved_change_to_email?
      EmailChangeNotifier.notify(@observable)
    end
  end

  def on_destroy_commit
    # Called after a user is destroyed and committed
    CleanupService.remove_user_data(@observable.id)
  end
end
```

The `@observable` instance variable contains the model instance that triggered the event.

### Skipping Observers

To bypass observers for a specific operation:

```ruby
user = User.new(name: "John Doe")
user.skip_observers = true
user.save  # No observer callbacks will be triggered
```

### Custom Observer Class Names

Override `observer_class_name` to use a non-conventional class name:

```ruby
class User < ApplicationRecord
  include ObservableModel::Sources::ActiveRecordObservable

  def observer_class_name
    "CustomUserObserver"
  end
end
```

### Organizing Observers

We recommend creating an `app/observers` directory in your Rails application:

```
app/
  observers/
    user_observer.rb
    order_observer.rb
    payment_observer.rb
```

Make sure to add this to your `config/application.rb`:

```ruby
config.autoload_paths += %W(#{config.root}/app/observers)
```

## How It Works

When you include `ObservableModel::Sources::ActiveRecordObservable` in your model, six callbacks are registered:

- `before_create` → `pre_create`
- `before_update` → `pre_update`
- `before_destroy` → `pre_destroy`
- `after_create_commit` → `on_create_commit`
- `after_update_commit` → `on_update_commit`
- `after_destroy_commit` → `on_destroy_commit`

On each event, the model looks up the observer class by convention, instantiates it with itself, and delegates the callback to it. If `skip_observers` is `true`, no observer is instantiated and all callbacks are silently skipped.

## Examples

### Example: Send Welcome Email on User Registration

```ruby
class UserObserver < ObservableModel::Observers::Base
  def on_create_commit
    UserMailer.welcome_email(@observable).deliver_later
  end
end
```

### Example: Validate State Before Destruction

```ruby
class OrderObserver < ObservableModel::Observers::Base
  def pre_destroy
    raise "Cannot delete a completed order" if @observable.completed?
  end
end
```

### Example: Track Order Status Changes

```ruby
class OrderObserver < ObservableModel::Observers::Base
  def on_update_commit
    if @observable.saved_change_to_status?
      OrderStatusNotifier.notify_customer(@observable)
      AnalyticsService.track_status_change(@observable)
    end
  end
end
```

### Example: Cleanup Related Data on Deletion

```ruby
class AccountObserver < ObservableModel::Observers::Base
  def on_destroy_commit
    DeleteUserDataJob.perform_later(@observable.id)
    AuditLog.create(action: 'account_deleted', account_id: @observable.id)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Run the test suite with:

```bash
$ bundle exec rake spec
```

## Roadmap

- [ ] Observer registration/configuration DSL
- [ ] Built-in async observer execution
- [ ] Observer metrics and monitoring hooks

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CodeTectonics/observable-model. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ObservableModel project's codebases and issue trackers is expected to follow the project's code of conduct.
