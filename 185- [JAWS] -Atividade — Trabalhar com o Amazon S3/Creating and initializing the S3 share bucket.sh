aws s3 mb s3://<cafe-xxxnnn> --region 'us-west-2'

aws s3 sync ~/initial-images/ s3://<cafe-xxxnnn>/images

aws s3 ls s3://<cafe-xxxnnn>/images/ --human-readable --summarize