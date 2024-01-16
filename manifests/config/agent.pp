define rke2::config::agent (
  String $filename = $name,
  Hash[String, Any] $values,
  Variant[Integer, String] $order = 50,
) {
  include rke2

  $order_actual = if $order =~ Integer {
    sprintf("%02d", $order)
  } else {
    $order
  }
  @file { "${rke2::config_yaml_dir}/${order_actual}-${filename}.yaml":
    content => stdlib::to_yaml($values, { indentation => 2 }),
    tag   => "rke2::config::agent",
  }
}
