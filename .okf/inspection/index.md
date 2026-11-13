# Inspection

* [RouteInspector](route-inspector.md) - Normalizes the Rails route set into flat route hashes and applies built-in and user filters.
* [ControllerInspector](controller-inspector.md) - Prism AST pass that extracts permitted attribute names from any permit call in a controller file.
* [SchemaInspector](schema-inspector.md) - Best-effort lookup of the ActiveRecord model behind a controller.
* [BodyInferrer](body-inferrer.md) - Composes ControllerInspector and SchemaInspector into typed body fields for create and update.
* [JsonRouteDetector](json-route-detector.md) - Static Prism-based classifier that decides whether a route returns JSON (--api-only).
