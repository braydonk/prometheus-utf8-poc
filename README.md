# utf-prometheus-poc

This repo is a proof of concept showing what changed between `v0.119.0` and `v0.121.0` of the collector (I believe the change happened in `v0.120.0`, but in our particular experiment `v0.121.0` is the version we care about comparing).

The gist is that when the Collector's `prometheusreceiver` updated to Prometheus 3, the same scrape config now suddenly successfully gets the utf-8 in the original names. This will break any OTel configs that relied on the names being converted to underscores.

## Run The Example

Requirements:
- make
- docker
- curl

Run `make run-example` to run the example. This will spin up two collectors, one at `v0.119.0` and one at `v0.121.0`, along with the program in `main.go` which uses the OpenTelemetry SDK to instrument an Int64Counter called `metric.counter` and export these metrics with the OTel Prometheus Exporter. The Collectors use the same config file, scrape the example program's metric, and run that through a filter that matches for either `metric_counter` or `metric.counter`. If you look in `otel119logs`, you will find in `otel.log` that only `metric_counter` is being found, whereas in `otel121logs` only `metric.counter` is being found.

## Looking directly at metrics

When scraping metrics from a spec-conformant Prometheus exporter, it decides what format to send the response in via Content-Type Negotiation. You can see the protocol names mapped to the `Content-Type` [here](https://github.com/prometheus/prometheus/blob/32d306854b77352fec62f5df1268d745b84dfd96/config/config.go#L516-L529).

The Makefile provides 4 targets to compare what `metric.counter` is exposed as in the different formats. The example must be running on your machine for these targets to work.

### make text-metrics

`make text-metrics` does a plain `curl` to the metrics endpoint. Since there is no `Accept` header provided in the request, it defaults to `PrometheusText0.0.4` which is `Content-Type: text/plain;version=0.0.4`.

```
$ make text-metrics
# HELP metric_counter_total a simple counter
# TYPE metric_counter_total counter
metric_counter_total{A="B",C="D",otel_scope_name="go.opentelemetry.io/contrib/examples/prometheus",otel_scope_version=""} 5
```

### make text-metrics-1.0.0

`make text-metrics-1.0.0` will request the protocol `PrometheusText1.0.0` by providing the header `Accept: text/plain;version=1.0.0`.

```
$ make text-metrics-1.0.0
# HELP metric_counter_total a simple counter
# TYPE metric_counter_total counter
metric_counter_total{A="B",C="D",otel_scope_name="go.opentelemetry.io/contrib/examples/prometheus",otel_scope_version=""} 5
```

### make text-metrics-utf8

`make text-metrics-utf8` will request the protocol `PrometheusText1.0.0` by providing the header `Accept: text/plain;version=1.0.0;escaping=allow-utf-8`. Note the new `escaping` directive as part of the header.

```
$ make text-metrics-utf8
# HELP "metric.counter_total" a simple counter
# TYPE "metric.counter_total" counter
{"metric.counter_total",A="B",C="D",otel_scope_name="go.opentelemetry.io/contrib/examples/prometheus",otel_scope_version=""} 5
```

### make text-metrics-proto

`make text-metrics-proto` will request the protocol `PrometheusProto` by providing the header `Accept: application/vnd.google.protobuf;proto=io.prometheus.client.MetricFamily;encoding=delimited`.

The output is piped to `less` and thus not as easy to paste here, but you can type `/metric.counter` to search the binary output and find the metric we need to see.