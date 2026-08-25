resource "aws_appautoscaling_target" "readers" {
  count = local.create_rds && var.autoscaling.enabled ? 1 : 0

  region             = var.region
  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.main[0].id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  min_capacity       = var.autoscaling.min_capacity
  max_capacity       = var.autoscaling.max_capacity
  tags               = local.common_tags
}

resource "aws_appautoscaling_policy" "readers" {
  count = local.create_rds && var.autoscaling.enabled ? 1 : 0

  region             = var.region
  name               = "${var.name}-reader-autoscaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.readers[0].service_namespace
  resource_id        = aws_appautoscaling_target.readers[0].resource_id
  scalable_dimension = aws_appautoscaling_target.readers[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling.target_value
    scale_in_cooldown  = var.autoscaling.scale_in_cooldown
    scale_out_cooldown = var.autoscaling.scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = var.autoscaling.predefined_metric
    }
  }
}
