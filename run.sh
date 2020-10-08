## Required Configuration variables
## Input Configuration
# INPUT_CONFIG_FILE - Metric Input Configuration file (e.g. input-config.yaml)
# METRIC_MAX_TIME - Metric End Timestamp (e.g. 1602123903)
# METRIC_STEP - Step Seconds (e.g. "3600" for 1 hour step)
# METRIC_DELAY - Delay Seconds (e.g. "3600" for 1 hour delay)
# METRIC_MATCH - Metric Matcher (e.g. up)
## Output configuration
# OUTPUT_FILE_TYPE - Output File Type (Default: parquet)
# OUTPUT_METRIC_RESOLUTION - Output Metric Resolution (e.g. 1h)
# STORAGE_CONFIG_FILE - Configuration for Metric output storage (e.g. storage-config.yaml)
# METRIC_STORAGE_PREFIX - String to be appended to the metric storage path (e.g. "/data/")


if [ -z "$METRIC_MAX_TIME" ]; then
    echo "ERROR: Required var METRIC_MAX_TIME not set" 1>&2
    exit 1
fi
if [ -z "$METRIC_STEP" ]||[ -z "$METRIC_DELAY" ]; then
    echo "ERROR: Required vars METRIC_STEP or METRIC_DELAY not set" 1>&2
    exit 1
fi
# metric_min_time = (metric_max_time - delay) - ((metric_max_time - delay) % step)
(( TARGET_TIMESTAMP = METRIC_MAX_TIME - METRIC_DELAY ))
(( METRIC_MAX_TIME_SECONDS = TARGET_TIMESTAMP - (TARGET_TIMESTAMP % METRIC_STEP) ))
(( METRIC_MIN_TIME_SECONDS = METRIC_MAX_TIME_SECONDS - METRIC_STEP ))

METRIC_MIN_TIME=$(date --date="@$METRIC_MIN_TIME_SECONDS"  +%FT%TZ -u)
METRIC_MAX_TIME=$(date --date="@$METRIC_MAX_TIME_SECONDS"  +%FT%TZ -u)

echo "Defined Metric Time Range: $METRIC_MIN_TIME - $METRIC_MAX_TIME"

OUTPUT_CONFIG_FILE=/tmp/output-config.yaml

# Default output type is parquet
if [ -z "$OUTPUT_FILE_TYPE" ]; then
    OUTPUT_FILE_TYPE="parquet"
fi

# Output file partitioning scheme:
# s3://BUCKET_NAME/metric=gc_duration_seconds/year=2020/month=09/day=10/1599696000.parquet
if [ -z "$METRIC_MIN_TIME" ]; then
    echo "ERROR: Required var METRIC_MIN_TIME not set" 1>&2
    exit 1
fi


TIMESTAMP="$(date --date="$METRIC_MIN_TIME" -u +%s)"
YEAR="$(date --date="$METRIC_MIN_TIME" -u +%Y)"
MONTH="$(date --date="$METRIC_MIN_TIME" -u +%m)"
DAY="$(date --date="$METRIC_MIN_TIME" -u +%d)"
OUTPUT_FILE_PATH="$METRIC_STORAGE_PREFIX""metric=$METRIC_MATCH/year=$YEAR/month=$MONTH/day=$DAY/$TIMESTAMP.$OUTPUT_FILE_TYPE"
echo "Output File will be stored at: $OUTPUT_FILE_PATH"

if [ -z "$STORAGE_CONFIG_FILE" ]; then
    echo "ERROR: Required var STORAGE_CONFIG_FILE not set" 1>&2
    exit 1
fi
yq w $STORAGE_CONFIG_FILE 'type' $OUTPUT_FILE_TYPE > $OUTPUT_CONFIG_FILE
yq w -i $OUTPUT_CONFIG_FILE 'path' "$OUTPUT_FILE_PATH"


if [ -z "$OUTPUT_METRIC_RESOLUTION" ]; then
    echo "ERROR: Required var OUTPUT_METRIC_RESOLUTION not set" 1>&2
    exit 1
fi
if [ -z "$METRIC_MATCH" ]; then
    echo "ERROR: Required var METRIC_MATCH not set" 1>&2
    exit 1
fi

obslytics export --input-config-file=$INPUT_CONFIG_FILE \
       --output-config-file=$OUTPUT_CONFIG_FILE \
       --resolution="$OUTPUT_METRIC_RESOLUTION" --min-time="$METRIC_MIN_TIME" --max-time="$METRIC_MAX_TIME"\
       --match="$METRIC_MATCH"
