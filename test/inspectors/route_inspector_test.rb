# frozen_string_literal: true

require "test_helper"
require "action_dispatch"

class RouteInspectorTest < Minitest::Test
  def setup
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      resources :users
      namespace :api do
        namespace :v1 do
          resources :posts, only: [:index, :show, :create]
        end
      end
      get "/health", to: "health#check"
    end
  end

  def test_extracts_basic_resourceful_routes
    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: @routes).call
    users = result.select { |r| r[:controller] == "users" }

    verbs_and_paths = users.map { |r| [r[:verb], r[:path]] }.sort
    assert_includes verbs_and_paths, ["GET",    "/users"]
    assert_includes verbs_and_paths, ["POST",   "/users"]
    assert_includes verbs_and_paths, ["GET",    "/users/:id"]
    assert_includes verbs_and_paths, ["PATCH",  "/users/:id"]
    assert_includes verbs_and_paths, ["PUT",    "/users/:id"]
    assert_includes verbs_and_paths, ["DELETE", "/users/:id"]
  end

  def test_preserves_namespaces_in_controller_path
    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: @routes).call
    posts  = result.select { |r| r[:controller] == "api/v1/posts" }

    assert_equal 3, posts.size
    paths = posts.map { |r| r[:path] }
    assert paths.all? { |p| p.start_with?("/api/v1/posts") }, paths.inspect
  end

  def test_strips_format_suffix
    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: @routes).call
    result.each do |route|
      refute_includes route[:path], "(.:format)", "found unstripped format in #{route[:path]}"
    end
  end

  def test_extracts_path_params
    result   = RailsApiDocs::Inspectors::RouteInspector.new(route_set: @routes).call
    show     = result.find { |r| r[:controller] == "users" && r[:action] == "show" }
    create   = result.find { |r| r[:controller] == "users" && r[:action] == "create" }

    assert_equal ["id"], show[:path_params]
    assert_empty create[:path_params]
  end

  def test_includes_custom_routes
    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: @routes).call
    health = result.find { |r| r[:controller] == "health" }

    assert health
    assert_equal "GET",     health[:verb]
    assert_equal "/health", health[:path]
    assert_equal "check",   health[:action]
  end

  def test_skips_internal_rails_routes
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      get "/rails/info/properties", to: "rails/info#properties"
      resources :users
    end

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes).call

    refute(result.any? { |r| r[:path].start_with?("/rails/info") })
    assert(result.any? { |r| r[:controller] == "users" })
  end

  def test_match_via_all_route_with_empty_verb_is_skipped
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      match "/catchall", to: "catchall#hit", via: :all
      resources :users, only: [:index]
    end

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes).call

    refute(result.any? { |r| r[:path] == "/catchall" })
    assert(result.any? { |r| r[:controller] == "users" })
  end

  def test_lambda_routes_without_controller_are_skipped
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      get "/lambda", to: ->(_env) { [200, {}, ["ok"]] }
      resources :users, only: [:index]
    end

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes).call

    refute(result.any? { |r| r[:path] == "/lambda" })
    assert(result.any? { |r| r[:controller] == "users" })
  end

  def test_match_with_multiple_verbs_yields_one_entry_per_verb
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      match "/things", to: "things#act", via: [:get, :post]
    end

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes).call
    verbs  = result.map { |r| r[:verb] }.sort

    assert_equal %w[GET POST], verbs
    assert(result.all? { |r| r[:path] == "/things" && r[:controller] == "things" })
  end

  def test_config_ignored_path_prefixes_filters_routes
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      get "/admin/dashboard", to: "admin#index"
      resources :users, only: [:index]
    end

    config = RailsApiDocs::Configuration.new
    config.ignored_path_prefixes = ["/admin"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call

    refute(result.any? { |r| r[:path].start_with?("/admin") })
    assert(result.any? { |r| r[:controller] == "users" })
  end

  def test_config_ignored_controllers_accepts_strings_and_regexps
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      get "/sign_in",  to: "devise/sessions#new"
      get "/sign_out", to: "devise/sessions#destroy"
      get "/health",   to: "health#check"
      resources :users, only: [:index]
    end

    config = RailsApiDocs::Configuration.new
    config.ignored_controllers = [/^devise\//, "health"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq

    assert_equal ["users"], controllers
  end

  def test_config_ignored_actions_filters_new_and_edit
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw { resources :users }

    config = RailsApiDocs::Configuration.new
    config.ignored_actions = %w[new edit]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    actions = result.map { |r| r[:action] }.uniq.sort

    refute_includes actions, "new"
    refute_includes actions, "edit"
    assert_includes actions, "create"
    assert_includes actions, "show"
  end

  # ---------------- only_controllers whitelist ----------------

  def test_only_controllers_with_bare_name_matches_across_namespaces
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users, only: [:index]
      namespace :api do
        namespace :v1 do
          resources :users, only: [:index]
        end
      end
      resources :posts, only: [:index]
    end

    config = RailsApiDocs::Configuration.new
    config.only_controllers = ["users"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq.sort

    assert_equal ["api/v1/users", "users"], controllers
  end

  def test_only_controllers_bare_name_respects_word_boundary
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users,        only: [:index]
      resources :super_users,  only: [:index]   # not a "users" controller — boundary should reject
    end

    config = RailsApiDocs::Configuration.new
    config.only_controllers = ["users"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq

    assert_equal ["users"], controllers
  end

  def test_only_controllers_with_slash_is_exact_match
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users, only: [:index]
      namespace :api do
        namespace :v1 do
          resources :users, only: [:index]
        end
      end
    end

    config = RailsApiDocs::Configuration.new
    config.only_controllers = ["api/v1/users"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq

    assert_equal ["api/v1/users"], controllers
  end

  def test_only_controllers_accepts_regexps
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users, only: [:index]
      namespace :api do
        namespace :v1 do
          resources :widgets, only: [:index]
          resources :gizmos,  only: [:index]
        end
      end
    end

    config = RailsApiDocs::Configuration.new
    config.only_controllers = [/^api\/v1\//]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq.sort

    assert_equal ["api/v1/gizmos", "api/v1/widgets"], controllers
  end

  def test_only_controllers_multiple_entries_are_unioned
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users,    only: [:index]
      resources :posts,    only: [:index]
      resources :comments, only: [:index]
    end

    config = RailsApiDocs::Configuration.new
    config.only_controllers = ["users", "posts"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq.sort

    assert_equal ["posts", "users"], controllers
  end

  def test_empty_only_controllers_means_no_whitelist_filtering
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users, only: [:index]
      resources :posts, only: [:index]
    end

    config = RailsApiDocs::Configuration.new
    config.only_controllers = []

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq.sort

    assert_equal ["posts", "users"], controllers
  end

  def test_ignored_controllers_wins_over_only_controllers_when_both_match
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users, only: [:index]
      resources :posts, only: [:index]
    end

    config = RailsApiDocs::Configuration.new
    config.only_controllers     = ["users", "posts"]
    config.ignored_controllers  = ["users"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq

    # users is in both — blacklist wins.
    assert_equal ["posts"], controllers
  end

  def test_ignored_controllers_now_uses_boundary_aware_suffix_match
    # New shared rule: a bare-name pattern in ignored_controllers matches
    # the controller in any namespace (was exact-match before — see CHANGELOG).
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :users, only: [:index]
      namespace :api do
        namespace :v1 do
          resources :users, only: [:index]
        end
      end
      resources :posts, only: [:index]
    end

    config = RailsApiDocs::Configuration.new
    config.ignored_controllers = ["users"]

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes, config: config).call
    controllers = result.map { |r| r[:controller] }.uniq

    # Both root `users` and namespaced `api/v1/users` filtered out.
    assert_equal ["posts"], controllers
  end

  def test_third_party_engine_mount_is_skipped_via_missing_controller
    # Engine mounts don't populate route.defaults[:controller], so our
    # existing "no controller, no extract" branch already handles them.
    require "rack"
    dummy_app = ->(_env) { [200, {}, ["dummy"]] }

    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      mount dummy_app, at: "/dummy"
      resources :users, only: [:index]
    end

    result = RailsApiDocs::Inspectors::RouteInspector.new(route_set: routes).call

    refute(result.any? { |r| r[:path].start_with?("/dummy") })
    assert(result.any? { |r| r[:controller] == "users" })
  end
end
