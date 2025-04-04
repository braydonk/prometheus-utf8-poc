
.PHONY: run-example
run-example: backup-logs
	docker compose up $(if $(REBUILD),--build,)

.PHONY: backup-logs
backup-logs:
	@LOGS_FOLDER=otel119logs $(MAKE) backup-logs-in-folder
	@LOGS_FOLDER=otel121logs $(MAKE) backup-logs-in-folder

.PHONY: backup-logs-in-folder
backup-logs-in-folder: DATE = $(shell date +"%Y%m%d_%H%M%S")
backup-logs-in-folder:
	@mv $(LOGS_FOLDER)/otel.log $(LOGS_FOLDER)/otel_$(DATE).log || true
	@mv $(LOGS_FOLDER)/metrics.json $(LOGS_FOLDER)/metrics_$(DATE).json || true

METRICS_URL ?= http://localhost:2223/metrics

.PHONY: text-metrics
text-metrics:
	@curl -s $(METRICS_URL) | grep "metric_counter"

.PHONY: text-metrics-utf8
text-metrics-utf8:
	@curl -s \
		-H "Accept: text/plain;version=1.0.0;escaping=allow-utf-8" \
		$(METRICS_URL) | \
		grep "metric.counter"

.PHONY: proto-metrics
proto-metrics: $(PROTOC_BIN)
	@curl -X GET -s \
		-H "Accept: application/vnd.google.protobuf;proto=io.prometheus.client.MetricFamily;encoding=delimited" \
		$(METRICS_URL) | \
	less

# I'm leaving this in here just in case, but I couldn't get protoc
# working for decoding the proto metrics.

PROTOC_BIN ?= .tools/protobuf/bin/protoc
PROTOC_VER = 30.2

.PHONY: protoc
protoc: $(PROTOC_BIN)

$(PROTOC_BIN):
	mkdir -p .tools
	cd .tools && \
		curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VER)/protoc-$(PROTOC_VER)-linux-x86_64.zip && \
		unzip ./protoc-$(PROTOC_VER)-linux-x86_64.zip -d protobuf && \
		rm protoc-$(PROTOC_VER)-linux-x86_64.zip
