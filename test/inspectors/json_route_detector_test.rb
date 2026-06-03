# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class JsonRouteDetectorTest < Minitest::Test
  def setup
    @tmpdir          = Dir.mktmpdir("rails-api-docs-jrd")
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

  def detector
    RailsApiDocs::Inspectors::JsonRouteDetector.new(root: @tmpdir)
  end

  # ---------- inheritance-based (controller is :api) ----------

  def test_controller_directly_inheriting_from_action_controller_api_is_json
    write_controller("users_controller.rb", <<~RUBY)
      class UsersController < ActionController::API
        def index; end
        def show;  end
      end
    RUBY

    d = detector
    assert d.call(controller: "users", action: "index")
    assert d.call(controller: "users", action: "show")
    assert d.call(controller: "users", action: "any_method")  # :api → all actions true
  end

  def test_controller_inheriting_through_application_controller_api_is_json
    write_controller("application_controller.rb", <<~RUBY)
      class ApplicationController < ActionController::API
      end
    RUBY
    write_controller("posts_controller.rb", <<~RUBY)
      class PostsController < ApplicationController
        def index; end
      end
    RUBY

    assert detector.call(controller: "posts", action: "index")
  end

  def test_custom_namespaced_base_controller_inheriting_api_is_json
    write_controller("api/base_controller.rb", <<~RUBY)
      module Api
        class BaseController < ActionController::API
        end
      end
    RUBY
    write_controller("api/v1/widgets_controller.rb", <<~RUBY)
      module Api
        module V1
          class WidgetsController < Api::BaseController
            def index; end
          end
        end
      end
    RUBY

    assert detector.call(controller: "api/v1/widgets", action: "index")
  end

  # ---------- inheritance-based (controller is :html) ----------

  def test_controller_inheriting_action_controller_base_without_render_json_is_not_json
    write_controller("application_controller.rb", <<~RUBY)
      class ApplicationController < ActionController::Base
      end
    RUBY
    write_controller("pages_controller.rb", <<~RUBY)
      class PagesController < ApplicationController
        def home; render :home; end
      end
    RUBY

    refute detector.call(controller: "pages", action: "home")
  end

  # ---------- per-action render-json detection ----------

  def test_html_controller_with_render_json_in_specific_action_is_json_for_that_action
    write_controller("application_controller.rb", <<~RUBY)
      class ApplicationController < ActionController::Base
      end
    RUBY
    write_controller("mixed_controller.rb", <<~RUBY)
      class MixedController < ApplicationController
        def index;  render :index; end
        def search; render json: { results: [] }; end
      end
    RUBY

    refute detector.call(controller: "mixed", action: "index")
    assert detector.call(controller: "mixed", action: "search")
  end

  def test_detects_render_json_inside_respond_to_block
    write_controller("application_controller.rb", <<~RUBY)
      class ApplicationController < ActionController::Base
      end
    RUBY
    write_controller("posts_controller.rb", <<~RUBY)
      class PostsController < ApplicationController
        def show
          respond_to do |format|
            format.html { render :show }
            format.json { render json: @post }
          end
        end
      end
    RUBY

    assert detector.call(controller: "posts", action: "show")
  end

  def test_detects_render_with_hash_rocket_json_form
    write_controller("application_controller.rb", <<~RUBY)
      class ApplicationController < ActionController::Base
      end
    RUBY
    write_controller("legacy_controller.rb", <<~RUBY)
      class LegacyController < ApplicationController
        def show
          render :json => @thing
        end
      end
    RUBY

    assert detector.call(controller: "legacy", action: "show")
  end

  # ---------- :unknown cases (strict: returns false) ----------

  def test_controller_file_missing_returns_false
    refute detector.call(controller: "ghost", action: "index")
  end

  def test_unresolvable_parent_class_falls_through_to_action_level
    # Parent is some gem class we can't find — controller is :unknown by
    # inheritance, but per-action render-json detection still runs.
    write_controller("widgets_controller.rb", <<~RUBY)
      class WidgetsController < SomeGem::CustomBase
        def show
          render json: @widget
        end

        def index
          # nothing here
        end
      end
    RUBY

    assert detector.call(controller: "widgets", action: "show")     # per-action wins
    refute detector.call(controller: "widgets", action: "index")    # no render json + :unknown chain
  end

  # ---------- caching / efficiency ----------

  def test_parses_each_controller_file_only_once_even_with_shared_parent
    write_controller("application_controller.rb", <<~RUBY)
      class ApplicationController < ActionController::API
      end
    RUBY
    write_controller("a_controller.rb", "class AController < ApplicationController; def x; end; end")
    write_controller("b_controller.rb", "class BController < ApplicationController; def x; end; end")
    write_controller("c_controller.rb", "class CController < ApplicationController; def x; end; end")

    parse_count    = 0
    original_parse = ::Prism.method(:parse_file)

    ::Prism.stub(:parse_file, ->(path) { parse_count += 1; original_parse.call(path) }) do
      d = detector
      d.call(controller: "a", action: "x")
      d.call(controller: "b", action: "x")
      d.call(controller: "c", action: "x")
      d.call(controller: "a", action: "x")  # cache hit — no re-parse
    end

    # 3 child files + 1 application_controller.rb = 4 parses total
    assert_equal 4, parse_count
  end

  # ---------- profile_for inspection ----------

  def test_profile_for_exposes_type_and_json_actions
    write_controller("application_controller.rb", "class ApplicationController < ActionController::Base; end")
    write_controller("mixed_controller.rb", <<~RUBY)
      class MixedController < ApplicationController
        def index;  render :index; end
        def search; render json: { results: [] }; end
        def export; render json: data; end
      end
    RUBY

    profile = detector.profile_for("mixed")
    assert_equal :html, profile[:type]
    assert_equal %w[search export].sort, profile[:json_actions].sort
  end
end
