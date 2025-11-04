import boto3, os, time, json

def lambda_handler(event, context):
    cf = boto3.client("cloudfront")
    cp = boto3.client("codepipeline")

    # CodePipeline passes a job ID — grab it if present
    job_id = event.get("CodePipeline.job", {}).get("id")

    try:
        # Invalidate CloudFront cache
        dist_id = os.environ["DISTRIBUTION_ID"]
        resp = cf.create_invalidation(
            DistributionId=dist_id,
            InvalidationBatch={
                "Paths": {"Quantity": 1, "Items": ["/*"]},
                "CallerReference": str(time.time())
            }
        )

        print(f"CloudFront invalidation started: {resp['Invalidation']['Id']}")

        if job_id:
            cp.put_job_success_result(jobId=job_id)

        return {"status": "Succeeded"}

    except Exception as e:
        print(f"Error: {e}")
        if job_id:
            cp.put_job_failure_result(
                jobId=job_id,
                failureDetails={"type": "JobFailed", "message": str(e)}
            )
        raise
