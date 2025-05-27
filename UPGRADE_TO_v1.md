# Upgrade to v1 from v0

This guide is intended to help you upgrade from v0 to v1 of the Fides Terraform module. The release of v1 introduces breaking changes and new functionality, so be sure to review the [CHANGELOG](./CHANGELOG.md) for more details.

The most significant changes are:

- The Fides configuration has been moved to Terraform variables
- Introduction of a CloudFront distribution for Fides and the Privacy Center

## 1. Update the module source

As always, update the module source to use the new version.

```hcl
module "fides_aws_ecs" {
  source = "github.com/ethyca/fides-terraform//fides-aws-ecs?depth=1&ref=fides-aws-ecs/v1.0.1"
  ...
}
```

## 2. Update the Fides configuration

As noted in the [CHANGELOG](./CHANGELOG.md), the Fides configuration has been moved to Terraform variables. This means that you will need to **update your Fides configuration to use the new variables**. In the v0 versions of the module, the Fides configuration was done through arbitrary environment variables in the `fides_additional_environment_variables` variable.

The following Terraform variables have been added in v1. These replace the need to manually configure environment variables and provide better validation and documentation:

### General Configuration

- `environment_type` - Controls which endpoints require authentication (maps to `FIDES__DEV_MODE`)
- `docker_credentials` - Docker Hub credentials for private images
- `custom_domain` - Custom domain name for CloudFront distribution
- `custom_domain_points_to_cdn` - Whether custom domain points to CloudFront

### CORS Configuration

- `fides_additional_cors_origins` - Additional CORS origins (maps to `FIDES__SECURITY__CORS_ORIGINS`)
- `fides_cors_origin_regex` - Regex for CORS origins (maps to `FIDES__SECURITY__CORS_ORIGIN_REGEX`)

### Database Configuration

- `fides_database_api_engine_pool_size` - API engine pool size (maps to `FIDES__DATABASE__API_ENGINE_POOL_SIZE`)
- `fides_database_api_engine_max_overflow` - API engine max overflow (maps to `FIDES__DATABASE__API_ENGINE_MAX_OVERFLOW`)
- `fides_database_api_engine_keepalives_idle` - API engine keepalives idle (maps to `FIDES__DATABASE__API_ENGINE_KEEPALIVES_IDLE`)
- `fides_database_api_engine_keepalives_interval` - API engine keepalives interval (maps to `FIDES__DATABASE__API_ENGINE_KEEPALIVES_INTERVAL`)
- `fides_database_api_engine_keepalives_count` - API engine keepalives count (maps to `FIDES__DATABASE__API_ENGINE_KEEPALIVES_COUNT`)
- `fides_database_task_engine_pool_size` - Task engine pool size (maps to `FIDES__DATABASE__TASK_ENGINE_POOL_SIZE`)
- `fides_database_task_engine_max_overflow` - Task engine max overflow (maps to `FIDES__DATABASE__TASK_ENGINE_MAX_OVERFLOW`)
- `fides_database_task_engine_keepalives_idle` - Task engine keepalives idle (maps to `FIDES__DATABASE__TASK_ENGINE_KEEPALIVES_IDLE`)
- `fides_database_task_engine_keepalives_interval` - Task engine keepalives interval (maps to `FIDES__DATABASE__TASK_ENGINE_KEEPALIVES_INTERVAL`)
- `fides_database_task_engine_keepalives_count` - Task engine keepalives count (maps to `FIDES__DATABASE__TASK_ENGINE_KEEPALIVES_COUNT`)

### Redis Configuration

- `fides_redis_default_ttl_seconds` - Default TTL for Redis keys (maps to `FIDES__REDIS__DEFAULT_TTL_SECONDS`)
- `fides_redis_identity_verification_code_ttl_seconds` - TTL for identity verification codes (maps to `FIDES__REDIS__IDENTITY_VERIFICATION_CODE_TTL_SECONDS`)

### Logging Configuration

- `fides_log_format` - Log message format (maps to `FIDES__LOGGING__SERIALIZATION`)

### Security Configuration

- `fides_security_dsr_testing_tools_enabled` - Enable DSR testing tools (maps to `FIDES__SECURITY__DSR_TESTING_TOOLS_ENABLED`)
- `fides_security_oauth_access_token_expire_minutes` - OAuth token expiration (maps to `FIDES__SECURITY__OAUTH_ACCESS_TOKEN_EXPIRE_MINUTES`)
- `fides_security_request_rate_limit_per_minute` - API rate limit (maps to `FIDES__SECURITY__REQUEST_RATE_LIMIT`)
- `fides_security_public_request_rate_limit_per_minute` - Public API rate limit (maps to `FIDES__SECURITY__PUBLIC_REQUEST_RATE_LIMIT`)
- `fides_security_identity_verification_attempt_limit` - Identity verification attempt limit (maps to `FIDES__SECURITY__IDENTITY_VERIFICATION_ATTEMPT_LIMIT`)

### Execution Configuration

- `fides_execution_masking_strict` - Strict masking mode (maps to `FIDES__EXECUTION__MASKING_STRICT`)
- `fides_execution_request_task_ttl` - Request task TTL (maps to `FIDES__EXECUTION__REQUEST_TASK_TTL`)
- `fides_execution_state_polling_interval` - State polling interval (maps to `FIDES__EXECUTION__STATE_POLLING_INTERVAL`)
- `fides_execution_custom_privacy_request_fields` - Custom privacy request fields (maps to `FIDES__EXECUTION__ALLOW_CUSTOM_PRIVACY_REQUEST_FIELD_COLLECTION` and `FIDES__EXECUTION__ALLOW_CUSTOM_PRIVACY_REQUEST_FIELD_EXECUTION`)
- `fides_execution_interrupted_task_requeue_interval` - Interrupted task requeue interval (maps to `FIDES__EXECUTION__INTERRUPTED_TASK_REQUEUE_INTERVAL`)

### Consent Configuration

- `fides_consent_tcf` - TCF consent configuration (maps to multiple `FIDES__CONSENT__` variables)
- `fides_consent_translations` - Translation configuration (maps to `FIDES__CONSENT__ENABLE_TRANSLATIONS`, `FIDES__CONSENT__ENABLE_OOB_TRANSLATIONS`, `FIDES__CONSENT__ENABLE_AUTO_TCF_TRANSLATION`)
- `fides_consent_webhook_access_token_expire_minutes` - Consent webhook token expiration (maps to `FIDES__SECURITY__CONSENT_WEBHOOK_ACCESS_TOKEN_EXPIRE_MINUTES`)

### Detection & Discovery Configuration

- `fides_detection_and_discovery_website_monitor` - Website monitor configuration (maps to `FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_*` variables)
- `fides_detection_and_discovery_website_monitor_api_key` - Website monitor API key (maps to `FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_SERVICE_API_KEY`)

### System Scanner Configuration

- `fides_system_scanner` - System scanner configuration (maps to `FIDESPLUS__SYSTEM_SCANNER__*` variables)
- `fides_system_scanner_pixie_api_key` - Pixie API key (maps to `FIDESPLUS__SYSTEM_SCANNER__PIXIE_API_KEY`)

### Celery Configuration

- `fides_celery` - Celery configuration (maps to `FIDES__CELERY__*` variables)

### Dictionary Configuration

- `fides_dictionary` - Dictionary service configuration (maps to `FIDESPLUS__DICTIONARY__*` variables)
- `fides_dictionary_api_key` - Dictionary API key (maps to `FIDESPLUS__DICTIONARY__DICTIONARY_SERVICE_API_KEY`)

### Endpoint Cache Configuration

- `fides_endpoint_cache_privacy_experience_cache_ttl` - Privacy experience cache TTL (maps to `FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_CACHE_TTL`)
- `fides_endpoint_cache_privacy_experience_gvl_translations_cache_ttl` - GVL translations cache TTL (maps to `FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_GVL_TRANSLATIONS_CACHE_TTL`)
- `fides_endpoint_cache_privacy_experience_meta_cache_ttl` - Privacy experience meta cache TTL (maps to `FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_META_CACHE_TTL`)
- `fides_endpoint_cache_get_property_by_path_cache_ttl` - Property by path cache TTL (maps to `FIDESPLUS__ENDPOINT_CACHE__GET_PROPERTY_BY_PATH_CACHE_TTL`)
- `fides_endpoint_cache_privacy_experience_meta_cache_size` - Privacy experience meta cache size (maps to `FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_META_CACHE_SIZE`)

### Infrastructure Configuration

- `s3_bucket_name_prefix` - S3 bucket name prefix for globally unique names
- `rds_apply_immediately` - Apply RDS changes immediately
- `workers` - Worker container configuration for different queue types
- `alb_logs_retention_days` - ALB access logs retention period

### Removed Variables

The following variable was removed: `fides_analytics_opt_out`

## 3. Review CloudFront Configuration

v1 introduces **CloudFront distributions** as a major new feature that sits in front of both Fides and the Privacy Center when custom domain names are configured.

- **Two separate CloudFront distributions** are created when `route53_config` is provided:
  - One for the Fides API (`fides_distribution`)
  - One for the Privacy Center (`privacy_center_distribution`)
- **Only created when using custom domains** - if you don't configure `route53_config`, no CloudFront distributions are created

### Network Architecture Changes

**v0 (Direct ALB):**

```
Route53 A Record → Application Load Balancer → ECS Tasks
```

**v1 (CloudFront + ALB):**

```
Route53 A Record → CloudFront Distribution → Application Load Balancer → ECS Tasks
```

### DNS Record Changes

**v0 Behavior:**

- Route53 A records pointed directly to ALB DNS names
- Single certificate per service

**v1 Behavior:**

- Route53 A records point to CloudFront distribution domain names when custom domains are used
- Fallback to ALB DNS names when CloudFront is not enabled
- Additional certificates created in us-east-1 for CloudFront

### Migration Implications

1. **DNS propagation time** - Route53 records will change from pointing to ALB to CloudFront
2. **Certificate provisioning** - New ACM certificates will be created in us-east-1
3. **Caching behavior** - Privacy Center responses may be cached (1-hour TTL)
4. **Geographic distribution** - Traffic will be served from CloudFront edge locations

## 4. Apply the Changes

Be sure to thoroughly review your `terraform plan` output for any forced replacements and monitor your deployment logs for any issues.

Apply the changes to your infrastructure using `terraform apply`.

Monitor your deployment logs for any issues and ensure that your new CloudFront distributions are working as expected.

This upgrade may incur downtime and should be performed during a maintenance window.
