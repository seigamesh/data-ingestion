terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_iam_role" "AWSGlueServiceRole-finance" {
  name = "AWSGlueServiceRole-finance"
}

## classifier
resource "aws_glue_classifier" "finance_earnings" {
    name            = "dolthub-finance-earnings"

  csv_classifier {
    delimiter       = ","
    quote_symbol    = "\""
    contains_header = "PRESENT"
    header          = ["act_symbol","date","when"]
  }
}

## crawlers
resource "aws_glue_crawler" "crawler_yfinance" {
  name          = "yfinance_daily_price"
  role          = data.aws_iam_role.AWSGlueServiceRole-finance.arn
  database_name = "dp_yfinance"

  s3_target {
    path = "s3://aws-datalake-finance/yfinance/price-daily"
  }

  schema_change_policy {
    delete_behavior = "LOG"
  }
}

resource "aws_glue_crawler" "crawler_earnings" {
  name          = "dolthub_finance_data"
  role          = data.aws_iam_role.AWSGlueServiceRole-finance.arn
  database_name = "dp_dolthub_finance"

  s3_target {
    path = "s3://aws-datalake-finance/dolthub/finance-api/earnings/"
  }

  classifiers = [aws_glue_classifier.finance_earnings.name]

  schema_change_policy {
    delete_behavior = "LOG"
  }
}

