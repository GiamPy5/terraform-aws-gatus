import os
import subprocess
import sys
import time
import json
import re
from urllib.parse import quote


param_name = os.environ["GATUS_CONFIG_SSM_PARAM"]
region = os.environ["AWS_REGION"]
destination = "/config/user_config.yaml"

storage_secret_ref = os.environ.get("STORAGE_SECRET")
oidc_secret_ref = os.environ.get("OIDC_SECRET")

PLACEHOLDER_PATTERN = re.compile(r"__FETCH_FROM_SECRET__\.([A-Za-z0-9_\-.]+)")


def log(message):
    sys.stdout.write(f"{message}\n")
    sys.stdout.flush()


def log_error(message):
    sys.stderr.write(f"{message}\n")
    sys.stderr.flush()


def run_aws_cli(base_args, *, query=None):
    command = ["aws", *base_args]
    if query:
        command.extend(["--query", query])
    command.extend(["--output", "text", "--region", region, "--no-cli-pager"])
    return subprocess.check_output(command, text=True)


def fetch_ssm_parameter(name):
    return run_aws_cli(
        ["ssm", "get-parameter", "--name", name, "--with-decryption"],
        query="Parameter.Value",
    )


class SecretCache:
    def __init__(self, sources):
        self._sources = sources
        self._cache = {}

    def get(self, prefix):
        ref = (self._sources.get(prefix) or "").strip()

        if not ref:
            log_error(
                f"⚠️  No secret provided for '{prefix}' placeholders; update task definition."
            )
            return None

        if prefix in self._cache:
            return self._cache[prefix]

        parsed = ref
        if ref.startswith("{") or ref.startswith("["):
            try:
                parsed = json.loads(ref)
            except json.JSONDecodeError:
                parsed = ref

        if isinstance(parsed, dict):
            secret_data = parsed
        else:
            secret_data = {"value": str(parsed)}

        log(f"Using inline {prefix} secret value from ECS environment")
        self._cache[prefix] = secret_data
        return secret_data


def replace_placeholders(config_str, secret_cache):
    """Replaces __FETCH_FROM_SECRET__.something placeholders using appropriate secrets."""
    matches = PLACEHOLDER_PATTERN.findall(config_str)

    if not matches:
        return config_str, []

    log(f"Detected {len(matches)} placeholders, fetching secrets as needed...")

    resolved_placeholders = []

    for key_path in matches:
        prefix, *nested_keys = key_path.split(".")

        if not nested_keys:
            log_error(
                f"⚠️  Placeholder '{key_path}' is missing a key name after the prefix"
            )
            continue

        secret_data = secret_cache.get(prefix)

        if secret_data is None:
            continue

        value = secret_data
        for part in nested_keys:
            if isinstance(value, dict):
                value = value.get(part)
            else:
                value = None
                break

        if value is None:
            log_error(
                f"⚠️  Key '{key_path}' not found in {prefix} secret (inline value)"
            )
            continue

        transformed_value = transform_secret_value(prefix, nested_keys, value)

        placeholder = f"__FETCH_FROM_SECRET__.{key_path}"
        config_str = config_str.replace(placeholder, transformed_value)
        log(f"→ Resolved {placeholder} via {prefix} inline secret")
        resolved_placeholders.append(key_path)

    return config_str, resolved_placeholders


def transform_secret_value(prefix, nested_keys, value):
    text = str(value)
    if prefix == "storage" and nested_keys:
        field = nested_keys[-1]
        if field in {"username", "password"}:
            # Ensure credentials remain URL-safe inside Postgres DSN
            return quote(text, safe="")
    return text


secret_cache = SecretCache({"storage": storage_secret_ref, "oidc": oidc_secret_ref})

backoffs = [0, 2, 4, 8, 16]

for attempt, delay in enumerate(backoffs, start=1):
    try:
        log(f"Fetching Gatus config from SSM (attempt {attempt})...")
        config_str = fetch_ssm_parameter(param_name)
        log(
            f"Retrieved config from SSM parameter {param_name} "
            f"({len(config_str.splitlines())} lines)"
        )

        config_str, resolved = replace_placeholders(config_str, secret_cache)

        with open(destination, "w", encoding="utf-8") as fh:
            fh.write(config_str)

        if resolved:
            log(
                "Resolved placeholders: "
                + ", ".join(sorted({f"{path}" for path in resolved}))
            )
        else:
            log("No placeholder replacements required.")

        log(
            f"✅ Final config written to {destination} "
            f"(placeholders resolved: {len(resolved)})"
        )
        sys.exit(0)

    except subprocess.CalledProcessError as exc:
        log_error(
            f"Fetch failed (attempt {attempt}): {exc}. Retrying after {delay} seconds..."
        )
        time.sleep(delay)
    except Exception as e:
        log_error(f"Unexpected error: {e}")
        time.sleep(delay)

log_error("Failed to fetch config after retries")
sys.exit(1)
