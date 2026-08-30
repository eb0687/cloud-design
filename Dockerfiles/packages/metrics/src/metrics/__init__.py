from prometheus_client import Counter
from starlette.types import ASGIApp, Message, Receive, Scope, Send


REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total number of HTTP requests.",
    ("service", "method", "route", "status"),
)
class MetricsMiddleware:
    def __init__(self, app: ASGIApp, service: str) -> None:
        self.app = app
        self.service = service

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http" or scope["path"] == "/metrics":
            await self.app(scope, receive, send)
            return

        user_agent = dict(scope.get("headers", [])).get(b"user-agent", b"")
        if user_agent.startswith(b"kube-probe/"):
            await self.app(scope, receive, send)
            return

        status_code = 500

        async def capture_status(message: Message) -> None:
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
            await send(message)

        try:
            await self.app(scope, receive, capture_status)
        finally:
            route = scope.get("route")
            route_name = getattr(route, "path", scope["path"])
            method = scope.get("method", "UNKNOWN")
            REQUEST_COUNT.labels(
                self.service, method, route_name, str(status_code)
            ).inc()
