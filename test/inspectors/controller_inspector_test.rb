# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class ControllerInspectorTest < Minitest::Test
  def setup
    @tmpdir          = Dir.mktmpdir("rails-api-docs-ci")
    @controllers_dir = File.join(@tmpdir, "app/controllers")
    FileUtils.mkdir_p(@controllers_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def write_controller(relative_path, content)
    full = File.join(@controllers_dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  def inspect_controller(controller)
    RailsApiDocs::Inspectors::ControllerInspector.new(controller: controller, root: @tmpdir).call
  end

  def test_extracts_flat_symbol_permits
    write_controller("users_controller.rb", <<~RUBY)
      class UsersController < ApplicationController
        def create
          @user = User.create(user_params)
        end

        private

        def user_params
          params.require(:user).permit(:name, :email, :password)
        end
      end
    RUBY

    assert_equal %w[name email password], inspect_controller("users")
  end

  def test_works_with_namespaced_controller_path
    write_controller("api/v1/posts_controller.rb", <<~RUBY)
      module Api
        module V1
          class PostsController < ApplicationController
            def post_params
              params.require(:post).permit(:title, :body)
            end
          end
        end
      end
    RUBY

    assert_equal %w[title body], inspect_controller("api/v1/posts")
  end

  def test_extracts_direct_permit_without_require
    write_controller("settings_controller.rb", <<~RUBY)
      class SettingsController < ApplicationController
        def update
          @settings.update(params.permit(:theme, :timezone))
        end
      end
    RUBY

    assert_equal %w[theme timezone], inspect_controller("settings")
  end

  def test_extracts_top_level_keys_of_nested_permits
    write_controller("orders_controller.rb", <<~RUBY)
      class OrdersController < ApplicationController
        def order_params
          params.require(:order).permit(:status, :total, items: [:name, :quantity])
        end
      end
    RUBY

    # `items` shows up as a top-level key (nested array is ignored).
    assert_equal %w[status total items], inspect_controller("orders")
  end

  def test_deduplicates_when_permits_appear_multiple_times
    write_controller("users_controller.rb", <<~RUBY)
      class UsersController < ApplicationController
        def create_params
          params.require(:user).permit(:name, :email)
        end

        def update_params
          params.require(:user).permit(:name, :avatar)
        end
      end
    RUBY

    assert_equal %w[name email avatar], inspect_controller("users")
  end

  def test_returns_empty_when_file_missing
    assert_empty inspect_controller("ghost")
  end

  def test_returns_empty_when_no_permits_present
    write_controller("health_controller.rb", <<~RUBY)
      class HealthController < ApplicationController
        def check
          render json: { ok: true }
        end
      end
    RUBY

    assert_empty inspect_controller("health")
  end
end
