function rke2::labels(Hash[String, String] *$labels) >> Array[String] {
  $labels.reduce |$l, $v| { $l + $v }.map |$k, $v| {
    "${k}=${v}"
  }
}
