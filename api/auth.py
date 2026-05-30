import base64

VALID_USERNAME = "admin"
VALID_PASSWORD = "password123"


def authenticate(handler) -> bool:
    """Return True if the request carries valid Basic Auth credentials."""
    auth_header = handler.headers.get("Authorization", "")

    if not auth_header.startswith("Basic "):
        return False

    try:
        decoded = base64.b64decode(auth_header[6:]).decode("utf-8")
        username, password = decoded.split(":", 1)
    except Exception:
        return False

    return username == VALID_USERNAME and password == VALID_PASSWORD
