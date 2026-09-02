# ObservableModel

[![Gem Version](https://badge.fury.io/rb/observable_model.svg)](https://badge.fury.io/rb/observable_model)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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
- 🔄 **Lifecycle hooks** - Respond to create, update, and destroy commits
- 🚫 **Skippable observers** - Disable observers per-instance when needed
- 🧩 **Convention-based** - Auto-discovers observer classes (e.g., `UserObserver` for `User`)
- ⚡ **After-commit callbacks** - Ensures database transactions complete before running observers
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

Or install it yourself as:

```bash
$ gem install observable_model
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

### Advanced Usage

#### Skipping Observers

Sometimes you need to bypass observers (e.g., in tests, bulk operations, or specific business logic):

```ruby
# Skip observers for a specific instance
user = User.new(name: "John Doe")
user.skip_observers = true
user.save  # No observer callbacks will be triggered
```

#### Custom Observer Class Names

If you need to customize the observer class name, override the `observer_class_name` method:

```ruby
class User < ApplicationRecord
  include ObservableModel::Sources::ActiveRecordObservable
  
  def observer_class_name
    "CustomUserObserver"
  end
end
```

#### Organizing Observers

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

ObservableModel uses ActiveRecord's `after_commit` callbacks to ensure observers are only triggered after database transactions successfully complete. This prevents observers from running if a transaction is rolled back.

When you include `ObservableModel::Sources::ActiveRecordObservable` in your model:

1. Three `after_*_commit` callbacks are registered
2. On each event, the model looks for a corresponding observer class
3. If found, the observer is instantiated with the model instance
4. The appropriate observer method is called (unless `skip_observers` is true)

## Examples

### Example: Send Welcome Email on User Registration

```ruby
class UserObserver < ObservableModel::Observers::Base
  def on_create_commit
    UserMailer.welcome_email(@observable).deliver_later
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

- [ ] Support for additional lifecycle events (before_save, etc.)
- [ ] Observer registration/configuration DSL
- [ ] Built-in async observer execution
- [ ] Observer metrics and monitoring hooks

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CodeTectonics/observable-model. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ObservableModel project's codebases and issue trackers is expected to follow the project's code of conduct.
