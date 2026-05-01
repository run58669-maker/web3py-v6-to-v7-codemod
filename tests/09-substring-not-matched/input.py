# Negative test: identifiers that CONTAIN a v6 type name as a substring must
# NOT be rewritten. Type-rename rules use exact-name regex on `identifier` nodes.

class MyWebsocketProviderWrapper:
    """Wraps an upstream provider, name happens to share a prefix."""
    pass


class WebsocketProviderConfig:
    """Configuration object — not the provider itself."""
    pass


def make_my_websocket_provider():
    return MyWebsocketProviderWrapper()


# Variable suffixed with the v6 name — also untouched.
custom_WebsocketProvider_factory = make_my_websocket_provider
