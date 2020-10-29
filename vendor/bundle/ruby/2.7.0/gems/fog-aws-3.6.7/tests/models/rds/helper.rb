def rds_default_server_params
  {
    :allocated_storage       => 5,
    :backup_retention_period => 0,
    :engine                  => 'mysql',
    :version                 => '5.6.22',
    :id                      => uniq_id,
    :master_username         => 'foguser',
    :password                => 'fogpassword',
    :flavor_id               => 'db.m3.medium',
  }
end

def rds_default_cluster_params
  {
    :allocated_storage       => 50,
    :backup_retention_period => 10,
    :engine                  => "aurora",
    :version                 => "5.6.10a",
    :id                      => uniq_id,
    :master_username         => "fogclusteruser",
    :password                => "fogpassword",
    :flavor_id               => "db.r3.large"
  }
end
