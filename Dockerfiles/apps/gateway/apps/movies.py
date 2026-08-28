from fastapi import Request, Response, HTTPException, status, APIRouter
from packages.env.src.env import GateEnvVars, load_env
from packages.logging.src import logging
import httpx

router = APIRouter(prefix="/api/movies", tags=["Movies"])
log = logging.get_logger("inventory")
config = load_env(GateEnvVars)


async def proxy_inventory_request(request: Request, path: str = "") -> Response:
    target_url = f"{config.GATE_INVENTORY_URL.rstrip('/')}/api/movies{path}"

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            upstream = await client.request(
                method=request.method,
                url=target_url,
                params=request.query_params,
                content=await request.body(),
                headers={
                    key: value
                    for key, value in request.headers.items()
                    if key.lower() != "host"
                },
            )
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Inventory service unavailable",
        )

    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        media_type=upstream.headers.get("content-type"),
    )


@router.api_route("/", methods=["GET", "POST", "DELETE"])
async def movies(request: Request) -> Response:
    return await proxy_inventory_request(request)


@router.api_route("/{movie_id}", methods=["GET", "PUT", "DELETE"])
async def movie(request: Request, movie_id: int) -> Response:
    return await proxy_inventory_request(request, f"/{movie_id}")
