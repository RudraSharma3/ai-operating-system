# Task: Authenticate Session via Vendored Library

## Objective
Configure user session creation in `app.py` by integrating with our internal vendored module `lib/session_auth.py`.

In previous legacy releases (v1/v2), developers called `create_session(user_id, ttl_seconds)` with positional arguments.
However, this vendored library has evolved.

## Requirements
1. Inspect the local vendored file `lib/session_auth.py` directly to verify its exact function signature and parameter requirements. Do not guess or assume parameter order.
2. Implement `init_user_session(user_id, tenant_id)` in `app.py` that delegates to `create_session` with valid arguments.
3. Pass `test_app.py` without modifying the vendored `lib/session_auth.py`.

