# This file has configuration and resources that are shared between the web server and the worker
locals {
  fides_environment_variables = concat(
    # Core settings
    [
      {
        name  = "FIDES__LOGGING__LEVEL"
        value = upper(var.fides_log_level)
      },
      {
        name  = "FIDES__DATABASE__SERVER"
        value = aws_db_instance.postgres.address
      },
      {
        name  = "FIDES__DATABASE__PORT"
        value = tostring(aws_db_instance.postgres.port)
      },
      {
        name  = "FIDES__DATABASE__DB"
        value = aws_db_instance.postgres.db_name
      },
      {
        name  = "FIDES__DATABASE__USER"
        value = aws_db_instance.postgres.username
      },
      {
        name  = "FIDES__DATABASE__ENABLED"
        value = "True"
      },
      {
        name  = "FIDES__REDIS__PORT"
        value = tostring(aws_elasticache_replication_group.fides_redis.port)
      },
      {
        name  = "FIDES__REDIS__HOST"
        value = aws_elasticache_replication_group.fides_redis.primary_endpoint_address
      },
      {
        name  = "FIDES__REDIS__SSL"
        value = "true"
      },
      {
        name  = "FIDES__REDIS__SSL_CERT_REQS"
        value = "none"
      },
      {
        name  = "FIDES__REDIS__DB_INDEX"
        value = "0"
      },
      {
        name  = "FIDES__REDIS__ENABLED"
        value = "True"
      },
      {
        name  = "FIDES__EXECUTION__SUBJECT_IDENTITY_VERIFICATION_REQUIRED"
        value = tostring(var.fides_identity_verification)
      },
      {
        name  = "FIDES__EXECUTION__REQUIRE_MANUAL_REQUEST_APPROVAL"
        value = tostring(var.fides_require_manual_request_approval)
      },
      {
        name  = "FIDES__SECURITY__ROOT_USERNAME"
        value = var.fides_root_user
      },
      {
        name  = "FIDES__SECURITY__CORS_ORIGINS"
        value = jsonencode(local.cors)
      },
      {
        name  = "FIDES__SECURITY__CORS_ORIGIN_REGEX"
        value = var.fides_cors_origin_regex
      },
      {
        name  = "FIDES__SECURITY__ENV"
        value = var.environment_type
      },
      # Dictionary settings
      {
        name  = "FIDESPLUS__DICTIONARY__ENABLED"
        value = tostring(var.fides_dictionary.enabled)
      },
      # Detection and Discovery settings
      {
        name  = "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_ENABLED"
        value = tostring(var.fides_detection_and_discovery_website_monitor.enabled)
      },
      # System Scanner settings
      {
        name  = "FIDESPLUS__SYSTEM_SCANNER__ENABLED"
        value = tostring(var.fides_system_scanner.enabled)
      },
      # Endpoint Cache settings
      {
        name  = "FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_CACHE_TTL"
        value = tostring(var.fides_endpoint_cache_privacy_experience_cache_ttl)
      },
      {
        name  = "FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_GVL_TRANSLATIONS_CACHE_TTL"
        value = tostring(var.fides_endpoint_cache_privacy_experience_gvl_translations_cache_ttl)
      },
      {
        name  = "FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_META_CACHE_TTL"
        value = tostring(var.fides_endpoint_cache_privacy_experience_meta_cache_ttl)
      },
      {
        name  = "FIDESPLUS__ENDPOINT_CACHE__GET_PROPERTY_BY_PATH_CACHE_TTL"
        value = tostring(var.fides_endpoint_cache_get_property_by_path_cache_ttl)
      },
      # GVL settings
      {
        name  = "FIDESPLUS__GVL__GVL_SOURCE_URL"
        value = var.fides_consent_tcf.gvl_source_url
      },
      # Celery configuration
      {
        name  = "FIDES__CELERY__EVENT_QUEUE_PREFIX"
        value = var.fides_celery.event_queue_prefix
      },
      {
        name  = "FIDES__CELERY__TASK_DEFAULT_QUEUE"
        value = var.fides_celery.task_default_queue
      },
      # Consent configuration
      {
        name  = "FIDES__CONSENT__ENABLE_TRANSLATIONS"
        value = tostring(var.fides_consent_translations.enable_translations)
      },
      {
        name  = "FIDES__CONSENT__ENABLE_OOB_TRANSLATIONS"
        value = tostring(var.fides_consent_translations.enable_oob_translations)
      },
      {
        name  = "FIDES__CONSENT__ENABLE_AUTO_TCF_TRANSLATION"
        value = tostring(var.fides_consent_translations.enable_auto_tcf_translations)
      },
      {
        name  = "FIDES__CONSENT__TCF_PUBLISHER_COUNTRY_CODE"
        value = var.fides_consent_tcf.tcf_publisher_country_code
      },
      {
        name  = "FIDES__CONSENT__PRIVACY_EXPERIENCES_TCF_DB_CACHE_ENABLED"
        value = tostring(var.fides_consent_tcf.privacy_experiences_tcf_db_cache_enabled)
      },
      {
        name  = "FIDES__CONSENT__PRIVACY_EXPERIENCES_ERROR_ON_CACHE_MISS"
        value = tostring(var.fides_consent_tcf.privacy_experiences_error_on_cache_miss)
      },
      {
        name  = "FIDES__SECURITY__CONSENT_WEBHOOK_ACCESS_TOKEN_EXPIRE_MINUTES"
        value = tostring(var.fides_consent_webhook_access_token_expire_minutes)
      }
    ],
    # Only add dictionary service URL if dictionary is enabled
    var.fides_dictionary.enabled ? [
      {
        name  = "FIDESPLUS__DICTIONARY__DICTIONARY_SERVICE_URL"
        value = var.fides_dictionary.dictionary_service_url
      }
    ] : [],
    # Only add detection and discovery settings if website monitor is enabled
    var.fides_detection_and_discovery_website_monitor.enabled ? [
      {
        name  = "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_SERVICE_URL"
        value = var.fides_detection_and_discovery_website_monitor.service_url
      },
      {
        name  = "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_POLLING_TIMEOUT_SECONDS"
        value = tostring(var.fides_detection_and_discovery_website_monitor.polling_timeout_seconds)
      },
      {
        name  = "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_RESULTS_PAGE_SIZE"
        value = tostring(var.fides_detection_and_discovery_website_monitor.website_monitor_results_page_size)
      }
    ] : [],
    # Only add system scanner settings if system scanner is enabled
    var.fides_system_scanner.enabled ? [
      {
        name  = "FIDESPLUS__SYSTEM_SCANNER__CLUSTER_ID"
        value = var.fides_system_scanner.cluster_id
      },
      {
        name  = "FIDESPLUS__SYSTEM_SCANNER__USE_ENCRYPTION"
        value = tostring(var.fides_system_scanner.use_encryption)
      },
      {
        name  = "FIDESPLUS__SYSTEM_SCANNER__PIXIE_CLOUD_SERVER_URL"
        value = var.fides_system_scanner.pixie_cloud_server_url
      }
    ] : []
  )

  fides_secrets = concat(
    [
      {
        name      = "FIDES__DATABASE__PASSWORD"
        valueFrom = aws_ssm_parameter.postgres_password.arn
      },
      {
        name      = "FIDES__REDIS__PASSWORD"
        valueFrom = aws_ssm_parameter.redis_auth_token.arn
      },
      {
        name      = "FIDES__SECURITY__APP_ENCRYPTION_KEY"
        valueFrom = aws_ssm_parameter.fides_encryption_key.arn
      },
      {
        name      = "FIDES__SECURITY__DRP_JWT_SECRET"
        valueFrom = aws_ssm_parameter.fides_drp_jwt_secret.arn
      },
      {
        name      = "FIDES__SECURITY__OAUTH_ROOT_CLIENT_ID"
        valueFrom = aws_ssm_parameter.fides_oauth_client_id.arn
      },
      {
        name      = "FIDES__SECURITY__OAUTH_ROOT_CLIENT_SECRET"
        valueFrom = aws_ssm_parameter.fides_oauth_client_secret.arn
      },
      {
        name      = "FIDES__SECURITY__ROOT_PASSWORD"
        valueFrom = aws_ssm_parameter.fides_root_password.arn
      }
    ],
    # Only include system scanner API key if system scanner is enabled
    (var.fides_system_scanner.enabled && var.fides_system_scanner_pixie_api_key != "") ? [
      {
        name      = "FIDES__SYSTEM_SCANNER__PIXIE_API_KEY"
        valueFrom = aws_ssm_parameter.fides_system_scanner_pixie_api_key[0].arn
      }
    ] : [],
    # Only include dictionary API key if dictionary is enabled
    (var.fides_dictionary.enabled && var.fides_dictionary_api_key != "") ? [
      {
        name      = "FIDESPLUS__DICTIONARY__DICTIONARY_SERVICE_API_KEY"
        valueFrom = aws_ssm_parameter.fides_dictionary_api_key[0].arn
      }
    ] : [],
    # Only include website monitor API key if website monitor is enabled
    (var.fides_detection_and_discovery_website_monitor.enabled && var.fides_detection_and_discovery_website_monitor_api_key != "") ? [
      {
        name      = "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_SERVICE_API_KEY"
        valueFrom = aws_ssm_parameter.fides_detection_and_discovery_website_monitor_api_key[0].arn
      }
    ] : []
  )
}
