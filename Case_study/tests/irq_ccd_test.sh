#!/usr/bin/env bash
set -e

VCACHE_MASK="003f003f"     # CPUs 0-5,12-17
FREQ_MASK="0fc0fc0"        # CPUs 6-11,18-23

GPU_IRQS=$(grep amdgpu /proc/interrupts | awk -F: '{print $1}' | tr -d ' ')

DURATION=84

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTDIR="irq_test_$TIMESTAMP"

mkdir -p "$OUTDIR"

echo "GPU IRQs detected:"
echo "$GPU_IRQS"

echo ""
echo "Select test mode:"
echo "1 = IRQ on Frequency CCD"
echo "2 = IRQ on VCache CCD"
read -r MODE

if [ "$MODE" = "1" ]; then
    MASK=$FREQ_MASK
    LABEL="freq_ccd"
elif [ "$MODE" = "2" ]; then
    MASK=$VCACHE_MASK
    LABEL="vcache_ccd"
else
    echo "Invalid mode"
    exit 1
fi

echo ""
echo "Applying affinity mask: $MASK"

for IRQ in $GPU_IRQS; do
    echo $MASK | sudo tee /proc/irq/$IRQ/smp_affinity > /dev/null
done

sleep 1

echo "Recording baseline interrupt counters"
cat /proc/interrupts > "$OUTDIR/${LABEL}_interrupts_before.txt"
cat /proc/softirqs > "$OUTDIR/${LABEL}_softirqs_before.txt"

echo ""
echo "Starting perf c2c recording..."
echo "Launch your game NOW and play for $DURATION seconds"

sudo perf c2c record -a -- sleep $DURATION

mv perf.data "$OUTDIR/${LABEL}_perf.data"

echo ""
echo "Recording post interrupt counters"

cat /proc/interrupts > "$OUTDIR/${LABEL}_interrupts_after.txt"
cat /proc/softirqs > "$OUTDIR/${LABEL}_softirqs_after.txt"

echo ""
echo "Generating perf c2c report"

sudo perf c2c report -i "$OUTDIR/${LABEL}_perf.data" \
    > "$OUTDIR/${LABEL}_c2c_report.txt"

echo ""
echo "Test complete"
echo "Results saved in $OUTDIR"
