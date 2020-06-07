// Redis resources

resource "aws_elasticache_cluster" "redis" {
    cluster_id         = "${var.PROJECT}-${var.ENV}"
    engine             = "redis"
    engine_version     = "4.0.10"
    node_type          = "cache.t2.small"
    num_cache_nodes    = 1
    port               = "6379"
    subnet_group_name  = aws_elasticache_subnet_group.redis.id
    security_group_ids = [aws_security_group.redis.id]
}