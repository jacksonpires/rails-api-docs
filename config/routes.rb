# frozen_string_literal: true

RailsApiDocs::Engine.routes.draw do
  root to: "docs#show", via: :get
end
