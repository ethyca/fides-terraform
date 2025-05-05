# General 

variable "environment_name" {
  description = "The environment name or identifier used to delineate separate Fides instances, e.g. qa, staging, production, etc."
  type        = string
  default     = "staging"

  validation {
    condition     = can(regex("[a-zA-Z][a-zA-Z0-9]{0,25}", var.environment_name))
    error_message = "The value of \"var.environment_name\" must contain only alphanumeric characters, begin with a letter, and cannot exceed 25 characters."
  }
}

variable "environment_type" {
  description = "The environment type, prod or dev, prod is recommended for non-development environments. This controls which endpoints require authentication."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "prod"], var.environment_type)
    error_message = "Environment type must be either \"dev\" or \"prod\"."
  }
}

variable "fides_image" {
  description = "The Fides Docker image to deploy."
  type        = string
  default     = "ethyca/fides"
}

variable "fides_version" {
  description = "The Fides version to deploy. Must be a valid Docker tag."
  type        = string
  default     = "2.60.0"
}

variable "privacy_center_image" {
  description = "The Fides Docker image to deploy."
  type        = string
  default     = "ethyca/fides-privacy-center"
}

variable "privacy_center_version" {
  description = "The Privacy Center version to deploy. Must be a valid Docker tag."
  type        = string
  default     = "2.60.0"
}

# AWS Networking

variable "aws_region" {
  description = "The AWS region to which the Fides resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "fides_primary_subnet" {
  description = "The subnet ID of the primary subnet that will contain Fides resources."
  type        = string
}

variable "fides_alternate_subnet" {
  description = "The subnet ID of the alternate subnet that may contain Fides resources. This subnet should be in a different availability zone from \"var.fides_primary_subnet\"."
  type        = string

  validation {
    condition     = var.fides_alternate_subnet != var.fides_primary_subnet
    error_message = "The alternate subnet ID cannot match the primary subnet ID."
  }
}

variable "allowed_ips" {
  description = "A list of IP addresses/ranges that are allowed to make inbound requests to the Fidesops API."
  type        = list(string)

  validation {
    condition     = can([for s in var.allowed_ips : cidrnetmask(s)])
    error_message = "Values within the list for \"allowed_ips\" must be valid IP addresses/ranges in CIDR notation."
  }
}

# DNS Configuration

variable "route53_config" {
  description = "Route53 DNS configuration for Fides and Privacy Center. Setting these values also creates a TLS certificate and serves traffic over port 443. In order to use these, you must have a hosted zone for the root domain."
  type = object({
    existing_hosted_zone_name = string # e.g. example.com
    fides_subdomain           = string # e.g. fides.example.com
    privacy_center_subdomain  = string # e.g. privacy.example.com
  })

  validation {
    condition     = var.route53_config.fides_subdomain != "" && var.route53_config.privacy_center_subdomain != "" && var.route53_config.existing_hosted_zone_name != ""
    error_message = "the value of \"var.route53_config.fides_subdomain\" and \"var.route53_config.privacy_center_subdomain\" must not be empty."
  }

  validation {
    condition     = startswith(var.route53_config.fides_subdomain, var.route53_config.existing_hosted_zone_name)
    error_message = "the value of \"var.route53_config.fides_subdomain\" must be a subdomain of \"var.route53_config.existing_hosted_zone_name\"."
  }

  validation {
    condition     = startswith(var.route53_config.privacy_center_subdomain, var.route53_config.existing_hosted_zone_name)
    error_message = "the value of \"var.route53_config.privacy_center_subdomain\" must be a subdomain of \"var.route53_config.existing_hosted_zone_name\"."
  }
}

# Fides Configuration

variable "fides_root_user" {
  description = "The root username to create."
  type        = string
  default     = "fidesroot"

  validation {
    condition     = length(var.fides_root_user) >= 4
    error_message = "the root username must be at least 4 characters long"
  }
}

variable "fides_root_password" {
  description = "The root user password to create. If one is not provided, one will be generated."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = length(var.fides_root_password) >= 12 || length(var.fides_root_password) == 0
    error_message = "the root password must be at least 12 characters long"
  }
}

variable "fides_additional_cors_origins" {
  description = "A list of CORS origins besides the privacy center and Fides Admin UI to allow. These can also be specified in the Fides Admin UI."
  type        = list(string)
  default     = []
}

variable "fides_cors_origin_regex" {
  description = "A regex to use to allowlist CORS origins, in addition to the 'fides_additional_cors_origins' list. For example: 'https://.*\\.example\\.com'"
  type        = string
  default     = ""
}

# Fides Database Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#application-database

variable "fides_database_api_engine_pool_size" {
  description = "The number of connections to keep open to the database."
  type        = number
  default     = 50
}

variable "fides_database_api_engine_max_overflow" {
  description = "The maximum number of connections to keep open to the database."
  type        = number
  default     = 50
}

variable "fides_database_api_engine_keepalives_idle" {
  description = "The number of seconds to wait before sending a keepalive to the database."
  type        = number
  default     = 30
}

variable "fides_database_api_engine_keepalives_interval" {
  description = "The number of seconds to wait between keepalives."
  type        = number
  default     = 10
}

variable "fides_database_api_engine_keepalives_count" {
  description = "Maximum number of TCP keepalive retries before the client considers the connection dead and closes it."
  type        = number
  default     = 5
}

variable "fides_database_task_engine_pool_size" {
  description = "The number of connections to keep open to the database."
  type        = number
  default     = 50
}

variable "fides_database_task_engine_max_overflow" {
  description = "The maximum number of connections to keep open to the database."
  type        = number
  default     = 50
}

variable "fides_database_task_engine_keepalives_idle" {
  description = "Number of seconds of inactivity before the client sends a TCP keepalive packet to verify the database connection is still alive."
  type        = number
  default     = 30
}

variable "fides_database_task_engine_keepalives_interval" {
  description = "Number of seconds between TCP keepalive retries if the initial keepalive packet receives no response."
  type        = number
  default     = 10
}

variable "fides_database_task_engine_keepalives_count" {
  description = "Maximum number of TCP keepalive retries before the client considers the connection dead and closes it."
  type        = number
  default     = 5
}

# Fides Redis Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#redis

variable "fides_redis_default_ttl_seconds" {
  description = "The default TTL for Redis keys."
  type        = number
  default     = 604800 # 7 days
}

variable "fides_redis_identity_verification_code_ttl_seconds" {
  description = "The TTL for Redis keys used for identity verification codes."
  type        = number
  default     = 600 # 10 minutes
}

# Fides Logging Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#logging

variable "fides_log_level" {
  description = "The logging level of Fides."
  type        = string
  default     = "INFO"

  validation {
    condition     = length(regexall("^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$", upper(var.fides_log_level))) > 0
    error_message = "the logging level must be one of the following values: \"DEBUG\", \"INFO\", \"WARNING\", \"ERROR\", or \"CRITICAL\""
  }
}

variable "fides_log_format" {
  description = "The format of the log messages."
  type        = string
  default     = "json"

  validation {
    condition     = contains(["json", ""], var.fides_log_format)
    error_message = "the log format must be one of the following values: \"json\", or \"\""
  }
}

# Fides Security Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#security

variable "fides_security_dsr_testing_tools_enabled" {
  description = "Whether to enable DSR testing tools. This should be disabled in production environments."
  type        = bool
  default     = false
}

variable "fides_security_oauth_access_token_expire_minutes" {
  description = "The number of minutes before the access token expires."
  type        = number
  default     = 11520 # 8 days
}

variable "fides_security_request_rate_limit_per_minute" {
  description = "The number of requests per minute allowed for the Fides API."
  type        = number
  default     = 1000
}

variable "fides_security_public_request_rate_limit_per_minute" {
  description = "The number of requests per minute allowed for the Fides API."
  type        = number
  default     = 1000
}

variable "fides_security_identity_verification_attempt_limit" {
  description = "The number of attempts allowed for identity verification."
  type        = number
  default     = 3
}

# Fides Execution Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#execution

variable "fides_identity_verification" {
  description = "Whether to require subject identity verification for privacy requests."
  type        = bool
  default     = false
}

variable "fides_require_manual_request_approval" {
  description = "Whether to require privacy requests to be approved before processing."
  type        = bool
  default     = false
}

variable "fides_execution_masking_strict" {
  description = "If set to True, only use UPDATE requests to mask data. If False, Fides will use any defined DELETE or GDPR DELETE endpoints to remove PII, which may extend beyond the specific data categories that configured in your execution policy."
  type        = bool
  default     = false
}

variable "fides_execution_request_task_ttl" {
  description = "The number of seconds a Request Task should live (Privacy Request subtasks). Older request tasks will be cleaned up from completed Privacy Requests periodically."
  type        = number
  default     = 604800 # 7 days
}

variable "fides_execution_state_polling_interval" {
  description = "The number of seconds between a scheduled process that checks to see if a Privacy Request's subtasks have \"completed\" and the overall Privacy Request needs to be placed in an errored state so it can be reprocessed."
  type        = number
  default     = 30
}

variable "fides_execution_custom_privacy_request_fields" {
  description = "Allows the collection and execution of custom privacy request fields from incoming privacy requests."
  type = object({
    allow_collection = bool
    allow_execution  = optional(bool, false)
  })
  default = {
    allow_collection = false # Allows the collection of custom privacy request fields from incoming privacy requests.
    allow_execution  = false # Allows the use of custom fields during the execution of privacy requests.
  }

  validation {
    condition     = !var.fides_execution_custom_privacy_request_fields.allow_execution || var.fides_execution_custom_privacy_request_fields.allow_collection
    error_message = "if var.fides_execution_custom_privacy_request_fields.allow_execution is true, var.fides_execution_custom_privacy_request_fields.allow_collection must also be true"
  }
}

variable "fides_execution_interrupted_task_requeue_interval" {
  description = "Seconds between polling for interrupted tasks to requeue."
  type        = number
  default     = 300
}

# Fides Consent Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#consent

variable "fides_consent_tcf" {
  description = "Consent configuration for Fides. Requires a Fides Enterprise license."
  type = object({
    tcf_enabled                              = bool                                                                     # Enables the IAB Transparency and Consent Framework. This feature requires additional configuration in the privacy center as well as a Fides Enterprise license.
    ac_enabled                               = optional(bool, false)                                                    # Enables the Google Ads additional consent string. Requires TCF and a Fides Enterprise license.
    override_vendor_purposes                 = optional(bool, false)                                                    # Allows for overriding the flexible legal legal basis of some TCF purposes.
    tcf_publisher_country_code               = optional(string, "")                                                     # The country code of the country that determines the legislation of reference. Commonly, this corresponds to the country in which the publisher's business entity is established.
    privacy_experiences_tcf_db_cache_enabled = optional(bool, true)                                                     # Enables caching of the TCF database in the privacy center.
    privacy_experiences_error_on_cache_miss  = optional(bool, false)                                                    # When set to True, the privacy center will display an error message if the TCF database cache is missed.
    gvl_source_url                           = optional(string, "https://vendor-list.consensu.org/v3/vendor-list.json") # The URL from which to fetch the official GVL vendor list.
  })
  default = {
    tcf_enabled = false
  }

  validation {
    condition     = !var.fides_consent_tcf.ac_enabled || var.fides_consent_tcf.tcf_enabled
    error_message = "if var.fides_consent_tcf.ac_enabled is true, var.fides_consent_tcf.tcf_enabled must also be true"
  }

  validation {
    condition     = can(regex("^https?://.*", var.fides_consent_tcf.gvl_source_url))
    error_message = "the value of \"var.fides_consent_tcf.gvl_source_url\" must be a valid URL"
  }
}

variable "fides_consent_translations" {
  description = "Translation configuration for Fides."
  type = object({
    enable_translations          = optional(bool, false) # Enables a customer to set their own content in various languages.
    enable_oob_translations      = optional(bool, false) # Enables translations on out-of-the-box Experiences and Notices.
    enable_auto_tcf_translations = optional(bool, false) # Enables automatic (server-side) translations of the minimal TCF experience response to the user's preferred language based on the Accept-Language header. WARNING: this can significantly decrease cache hit ratios and reduce performance.
  })
}

variable "fides_consent_webhook_access_token_expire_minutes" {
  description = "The time in minutes for which consent webhook access tokens will be valid."
  type        = number
  default     = 129600 # 90 days
}

# Fides Detection & Discovery Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#detection-and-discovery

variable "fides_detection_and_discovery_website_monitor" {
  description = "Detection and discovery configuration for Fides."
  type = object({
    enabled                           = optional(bool, false)
    service_url                       = optional(string, "")
    polling_timeout_seconds           = optional(number, 300)
    website_monitor_results_page_size = optional(number, 100)
  })
  default = {}
}

variable "fides_detection_and_discovery_website_monitor_api_key" {
  description = "The API key for the website monitor."
  type        = string
  sensitive   = true

  validation {
    condition     = var.fides_detection_and_discovery_website_monitor.enabled && var.fides_detection_and_discovery_website_monitor_api_key != ""
    error_message = "the value of \"var.fides_detection_and_discovery_website_monitor_api_key\" must not be empty if \"var.fides_detection_and_discovery_website_monitor.enabled\" is true"
  }
}

# System Scanner Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#system-scanner-settings

variable "fides_system_scanner" {
  description = "System scanner configuration for Fides."
  type = object({
    enabled                = optional(bool, false)
    cluster_id             = optional(string, "")
    use_encryption         = optional(bool, false)
    pixie_cloud_server_url = optional(string, "work.getcosmic.ai")
  })
}
variable "fides_system_scanner_pixie_api_key" {
  description = "The API key for the Pixie system scanner."
  type        = string
  sensitive   = true

  validation {
    condition     = var.fides_system_scanner.enabled && var.fides_system_scanner_pixie_api_key != ""
    error_message = "the value of \"var.fides_system_scanner_pixie_api_key\" must not be empty if \"var.fides_system_scanner.enabled\" is true"
  }
}

# Fides Celery Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#celery-configuration

variable "fides_celery" {
  description = "Celery configuration for Fides."
  type = object({
    event_queue_prefix = optional(string, "fides_worker")
    task_default_queue = optional(string, "fides")
  })
}

# Fides Dictionary Configuration
# https://ethyca.com/docs/dev-docs/configuration/configuration#dictionary

variable "fides_dictionary" {
  description = "Compass configuration for Fides."
  type = object({
    enabled                = optional(bool, false)
    dictionary_service_url = optional(string, "")
  })
  default = {}
}

variable "fides_dictionary_api_key" {
  description = "The API key for the dictionary service."
  type        = string
  sensitive   = true

  validation {
    condition     = var.fides_dictionary.enabled && var.fides_dictionary_api_key != ""
    error_message = "the value of \"var.fides_dictionary_api_key\" must not be empty if \"var.fides_dictionary.enabled\" is true"
  }
}

# Fidesplus Endpoint Cache  
# https://ethyca.com/docs/dev-docs/configuration/configuration#endpoint-cache-settings

variable "fides_endpoint_cache_privacy_experience_cache_ttl" {
  description = "The TTL for the privacy experience cache. Set to 0 to disable caching."
  type        = number
  default     = 3600 # 1 hour

  validation {
    condition     = var.fides_endpoint_cache_privacy_experience_cache_ttl >= 0
    error_message = "the value of \"var.fides_endpoint_cache_privacy_experience_cache_ttl\" must be greater than or equal to 0"
  }
}

variable "fides_endpoint_cache_privacy_experience_gvl_translations_cache_ttl" {
  description = "The TTL for the GVL translations cache. Set to 0 to disable caching."
  type        = number
  default     = 86400 # 1 day

  validation {
    condition     = var.fides_endpoint_cache_privacy_experience_gvl_translations_cache_ttl >= 0
    error_message = "the value of \"var.fides_endpoint_cache_privacy_experience_gvl_translations_cache_ttl\" must be greater than or equal to 0"
  }
}

variable "fides_endpoint_cache_privacy_experience_meta_cache_ttl" {
  description = "The TTL for the privacy experience meta cache. Set to 0 to disable caching."
  type        = number
  default     = 3600 # 1 hour

  validation {
    condition     = var.fides_endpoint_cache_privacy_experience_meta_cache_ttl >= 0
    error_message = "the value of \"var.fides_endpoint_cache_privacy_experience_meta_cache_ttl\" must be greater than or equal to 0"
  }
}

variable "fides_endpoint_cache_get_property_by_path_cache_ttl" {
  description = "The TTL for the get property by path cache. Set to 0 to disable caching."
  type        = number
  default     = 3600 # 1 hour

  validation {
    condition     = var.fides_endpoint_cache_get_property_by_path_cache_ttl >= 0
    error_message = "the value of \"var.fides_endpoint_cache_get_property_by_path_cache_ttl\" must be greater than or equal to 0"
  }
}

variable "fides_endpoint_cache_privacy_experience_meta_cache_size" {
  description = "The size of the meta cache. Set to 0 to disable caching."
  type        = number
  default     = 1000

  validation {
    condition     = var.fides_endpoint_cache_privacy_experience_meta_cache_size >= 0
    error_message = "the value of \"var.fides_endpoint_cache_privacy_experience_meta_cache_size\" must be greater than or equal to 0"
  }
}

# Fides Additional Environment Variables
variable "fides_additional_environment_variables" {
  description = "Additional environment variables to be passed to the container."
  type = list(object({
    name  = string,
    value = string
  }))
  sensitive = true
  default   = []

  validation {
    condition = length(var.fides_additional_environment_variables) == 0 || alltrue([
      for x in var.fides_additional_environment_variables : !contains([
        "FIDES__DATABASE__USER",
        "FIDES__DATABASE__PASSWORD",
        "FIDES__DATABASE__SERVER",
        "FIDES__DATABASE__PORT",
        "FIDES__DATABASE__DB",
        "FIDES__EXECUTION__REQUIRE_MANUAL_REQUEST_APPROVAL",
        "FIDES__EXECUTION__SUBJECT_IDENTITY_VERIFICATION_REQUIRED",
        "FIDES__LOGGING__LEVEL",
        "FIDES__REDIS__HOST",
        "FIDES__REDIS__PORT",
        "FIDES__REDIS__PASSWORD",
        "FIDES__REDIS__CONNECTION_URL",
        "FIDES__SECURITY__APP_ENCRYPTION_KEY",
        "FIDES__SECURITY__OAUTH_ROOT_CLIENT_ID",
        "FIDES__SECURITY__OAUTH_ROOT_CLIENT_SECRET",
        "FIDES__SECURITY__ROOT_PASSWORD",
        "FIDES__SECURITY__ROOT_USERNAME",
        "FIDES__SYSTEM_SCANNER__PIXIE_API_KEY",
        "FIDESPLUS__DICTIONARY__ENABLED",
        "FIDESPLUS__DICTIONARY__DICTIONARY_SERVICE_URL",
        "FIDESPLUS__DICTIONARY__DICTIONARY_SERVICE_API_KEY",
        "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_ENABLED",
        "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_SERVICE_URL",
        "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_SERVICE_API_KEY",
        "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_POLLING_TIMEOUT_SECONDS",
        "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_RESULTS_PAGE_SIZE",
        "FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_CACHE_TTL",
        "FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_GVL_TRANSLATIONS_CACHE_TTL",
        "FIDESPLUS__ENDPOINT_CACHE__PRIVACY_EXPERIENCE_META_CACHE_TTL",
        "FIDESPLUS__ENDPOINT_CACHE__GET_PROPERTY_BY_PATH_CACHE_TTL",
        "FIDESPLUS__GVL__GVL_SOURCE_URL",
        "FIDESPLUS__SYSTEM_SCANNER__ENABLED",
        "FIDESPLUS__SYSTEM_SCANNER__CLUSTER_ID",
        "FIDESPLUS__SYSTEM_SCANNER__PIXIE_API_KEY",
        "FIDESPLUS__SYSTEM_SCANNER__USE_ENCRYPTION",
        "FIDESPLUS__SYSTEM_SCANNER__PIXIE_CLOUD_SERVER_URL",
        "FIDES__CELERY__EVENT_QUEUE_PREFIX",
        "FIDES__CELERY__TASK_DEFAULT_QUEUE",
        "FIDES__CELERY__TASK_ALWAYS_EAGER",
        "FIDES__CONSENT__MAX_RAPID_CONSENT_ROWS",
        "FIDES__CONSENT__RAPID_CONSENT_DB_BUFFER_SIZE",
        "FIDES__CONSENT__ENABLE_TRANSLATIONS",
        "FIDES__CONSENT__ENABLE_OOB_TRANSLATIONS",
        "FIDES__CONSENT__ENABLE_AUTO_TCF_TRANSLATION",
        "FIDES__CONSENT__TCF_PUBLISHER_COUNTRY_CODE",
        "FIDES__CONSENT__PRIVACY_EXPERIENCES_TCF_DB_CACHE_ENABLED",
        "FIDES__CONSENT__PRIVACY_EXPERIENCES_ERROR_ON_CACHE_MISS",
        "FIDES__SECURITY__CONSENT_WEBHOOK_ACCESS_TOKEN_EXPIRE_MINUTES"
      ], x.name)
    ])
    error_message = "cannot pass in that environment variable, reserved for internal use - use the native Terraform variables instead."
  }
}

# Privacy Center Configuration

variable "privacy_center_configuration_file" {
  description = "The file path of a config.json file with which to configure the Privacy Center."
  type        = string
  default     = ""

  validation {
    condition     = var.privacy_center_configuration_file != "" ? fileexists(var.privacy_center_configuration_file) : true
    error_message = "no file found for the value of \"var.privacy_center_configuration_file\""
  }

  validation {
    condition     = var.privacy_center_configuration_file != "" ? can(jsondecode(file(var.privacy_center_configuration_file))) : true
    error_message = "the value of \"var.privacy_center_configuration_file\" must be valid JSON"
  }
}

variable "privacy_center_css_file" {
  description = "The file path of a config.css file with which to style the Privacy Center."
  type        = string
  default     = ""

  validation {
    condition     = var.privacy_center_css_file != "" ? fileexists(var.privacy_center_css_file) : true
    error_message = "no file found for the value of \"var.privacy_center_css_file\""
  }
}

# Fides Resources - ECS Fargate

variable "fides_cpu" {
  description = "The number of CPU units to dedicate to the Fides container."
  type        = number
  default     = 1024
}

variable "fides_memory" {
  description = "The amount of memory, in MiB, to dedicate to the Fides container."
  type        = number
  default     = 2048
}

# Load Balancer

variable "lb_name" {
  description = "The name of the load balancer. If one is not provided, one will be generated."
  type        = string
  default     = ""
}

# Postgres

variable "rds_name" {
  description = "The name of the RDS instance. If one is not provided, one will be generated."
  type        = string
  default     = ""
}

variable "rds_postgres_version" {
  description = "The version of the RDS PostgreSQL engine."
  type        = string
  default     = "14.17"
}

variable "rds_multi_az" {
  description = "Configure RDS to use a multi-AZ deployment."
  type        = bool
  default     = false
}

variable "rds_instance_class" {
  description = "The instance class of the RDS instance."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "The amount of storage, in GiB, to assign to the RDS instance."
  type        = number
  default     = 10
}

# Redis

variable "elasticache_node_type" {
  description = "The node type of the Fides Elasticache cluster."
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_auto_failover" {
  description = "Enable automatic failover on the Elasticache cluster."
  type        = bool
  default     = false
}

# SSM Parameter Store

variable "ssm_parameter_prefix" {
  description = "The prefix for AWS SSM Parameter Store entries related to Fides."
  type        = string
  default     = "/fides"
}

# Privacy Center Resources - ECS Fargate

variable "privacy_center_cpu" {
  description = "The number of CPU units to dedicate to the Privacy Center container."
  type        = number
  default     = 512
}

variable "privacy_center_memory" {
  description = "The amount of memory, in MiB, to dedicate to the Privacy Center container."
  type        = number
  default     = 1024
}

variable "workers" {
  description = "The configuration for the worker container."
  type = list(object({
    name           = string
    queues         = optional(list(string))
    exclude_queues = optional(list(string))
    count          = optional(number, 1)
    cpu            = number
    memory         = number
  }))
  default = [
    {
      name   = "dsr"
      queues = ["fides.dsr"]
      cpu    = 1024
      memory = 2048
    },
    {
      name   = "privacy_preferences"
      queues = ["fides.privacy_preferences"]
      cpu    = 512
      memory = 1024
    },
    {
      name           = "other"
      exclude_queues = ["fides.dsr", "fides.privacy_preferences"]
      cpu            = 512
      memory         = 1024
  }]

  validation {
    condition     = alltrue([for w in var.workers : w.cpu > 0 && w.memory > 0])
    error_message = "the cpu and memory values of \"var.workers\" must be greater than 0"
  }

  validation {
    condition     = alltrue([for w in var.workers : w.queues != null && w.exclude_queues != null])
    error_message = "the value of a given worker in \"var.workers\" must not contain both queues and exclude_queues"
  }

  validation {
    condition     = length(var.workers) == length(distinct([for w in var.workers : w.name]))
    error_message = "the names of workers in \"var.workers\" must be unique."
  }

  validation {
    condition     = alltrue([for w in var.workers : can(regex("^[a-zA-Z0-9-]+$", w.name)) && length(w.name) >= 3])
    error_message = "the names of workers in \"var.workers\" must contain only alphanumeric characters or dashes and must be at least 3 characters long"
  }
}

# Cloudwatch Logs

variable "cloudwatch_log_group" {
  description = "The ARN of the CloudWatch Logs group to use. If not specified, one will be created."
  type        = string
  default     = ""
}
