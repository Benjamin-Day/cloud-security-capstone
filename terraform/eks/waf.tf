data "aws_wafv2_ip_set" "argocd" {
  name  = "ArgoCDAccess"
  scope = "REGIONAL"
}

resource "aws_wafv2_web_acl" "waf" {
  name = "${local.env}-alb-waf"

  description = "WAF for alb for eks cluster"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-common-rule-set"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "api.<DOMAIN>"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "common-rule-set"
    }
  }

  rule {
    name     = "aws-linux-rule-set"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "api.<DOMAIN>"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "linux-rule-set"
    }
  }

  rule {
    name     = "aws-known-bad-inputs-rule-set"
    priority = 3

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "api.<DOMAIN>"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "bad-inputs-rule-set"
    }
  }

  rule {
    name     = "aws-ip-reputation-rule-set"
    priority = 4

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "api.<DOMAIN>"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "ip-reputation-rule-set"
    }
  }

  rule {
    name     = "rate-limit"
    priority = 5

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
        limit                 = 100

        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "api.<DOMAIN>"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "rate-limiting-rule-set"
    }
  }

  rule {
    name     = "argocd-ip-list"
    priority = 6

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "argocd.<DOMAIN>"
            text_transformation {
              type     = "NONE"
              priority = "0"
            }
          }
        }
        statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = data.aws_wafv2_ip_set.argocd.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "rate-limiting-rule-set"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
    metric_name                = "capstone-alb-waf"
  }

  # checkov:skip=CKV2_AWS_31: "Ensure WAF2 has a Logging Configuration"
  # Not going to be able to enable this due to costs
}

resource "aws_wafv2_web_acl_association" "alb" {
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
  resource_arn = data.aws_lb.alb.arn
}