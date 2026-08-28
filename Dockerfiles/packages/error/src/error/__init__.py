from typing import Any

from pydantic import BaseModel


class ErrorResponse(BaseModel):
    detail: str


common_responses: dict[int | str, dict[str, Any]] = {
    404: {
        "model": ErrorResponse,
        "description": "Resource not found",
    },
    500: {
        "description": "Internal server error",
    },
}
