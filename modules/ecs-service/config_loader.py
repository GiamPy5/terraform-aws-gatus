import os
import subprocess
import sys
import time
import json
import re

param_name = os.environ["GATUS_CONFIG_SSM_PARAM"]
region = os.environ["AWS_REGION"]
destination = "/config/user_config.yaml"

storage_secret_arn = os.environ.get("STORAGE_SECRET_ARN")
oidc_secret_arn = os.environ.get("OIDC_SECRET_ARN")


def fetch_ssm_parameter(name):
    cli_command = [
        "aws",
        "ssm",
        "get-parameter",
        "--name",
        name,
        "--with-decryption",
        "--query",
        "Parameter.Value",
        "--output",
        "text",
        "--region",
        region,
        "--no-cli-pager",
    ]
    return subprocess.check_output(cli_command, text=True)


def fetch_secret(arn):
    cli_command = [
        "aws",
        "secretsmanager",
        "get-secret-value",
        "--secret-id",
        arn,
        "--query",
        "SecretString",
        "--output",
        "text",
        "--region",
        region,
        "--no-cli-pager",
    ]
    output = subprocess.check_output(cli_command, text=True)
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        return {"value": output}


def replace_placeholders(config_str):
    """Replaces __FETCH_FROM_SECRET__.something placeholders using appropriate secrets."""
    pattern = re.compile(r"__FETCH_FROM_SECRET__\.([A-Za-z0-9_\-\.]+)")
    matches = pattern.findall(config_str)

    if not matches:
        return config_str

    sys.stdout.write(
        f"Detected {len(matches)} placeholders, fetching secrets as needed...\n"
    )
    sys.stdout.flush()

    # Lazy-fetch secrets only when needed
    cached_secrets = {}

    for key_path in matches:
        # Determine which secret to use
        if key_path.startswith("storage.") and storage_secret_arn:
            secret_arn = storage_secret_arn
            secret_name = "storage"
        elif key_path.startswith("oidc.") and oidc_secret_arn:
            secret_arn = oidc_secret_arn
            secret_name = "oidc"
        else:
            sys.stderr.write(f"⚠️  No secret ARN configured for key '{key_path}'\n")
            continue

        # Fetch secret if not already fetched
        if secret_arn not in cached_secrets:
            sys.stdout.write(f"Fetching {secret_name} secret from {secret_arn}\n")
            sys.stdout.flush()
            cached_secrets[secret_arn] = fetch_secret(secret_arn)

        secret_data = cached_secrets[secret_arn]

        # Extract nested key, e.g. oidc.client-id → client-id
        parts = key_path.split(".")[1:]  # remove the prefix (storage/oidc)
        secret_key = parts[-1]
        value = secret_data
        for part in parts[1:]:  # allow deeper nesting
            if isinstance(value, dict):
                value = value.get(part)
            else:
                value = None
                break

        if value is not None:
            placeholder = f"__FETCH_FROM_SECRET__.{key_path}"
            config_str = config_str.replace(placeholder, str(value))
            sys.stdout.write(f"→ Replaced {placeholder} with secret value.\n")
        else:
            sys.stderr.write(f"⚠️  Key '{key_path}' not found in secret {secret_arn}\n")

    return config_str


backoffs = [0, 2, 4, 8, 16]

for attempt, delay in enumerate(backoffs, start=1):
    try:
        sys.stdout.write(f"Fetching Gatus config from SSM (attempt {attempt})...\n")
        sys.stdout.flush()
        config_str = fetch_ssm_parameter(param_name)

        config_str = replace_placeholders(config_str)

        with open(destination, "w", encoding="utf-8") as fh:
            fh.write(config_str)

        sys.stdout.write(f"✅ Final config written to {destination}\n")
        sys.stdout.flush()
        sys.exit(0)

    except subprocess.CalledProcessError as exc:
        sys.stderr.write(
            f"Fetch failed (attempt {attempt}): {exc}. Retrying after {delay} seconds...\n"
        )
        sys.stderr.flush()
        time.sleep(delay)
    except Exception as e:
        sys.stderr.write(f"Unexpected error: {e}\n")
        sys.stderr.flush()
        time.sleep(delay)

sys.stderr.write("Failed to fetch config after retries\n")
sys.exit(1)
