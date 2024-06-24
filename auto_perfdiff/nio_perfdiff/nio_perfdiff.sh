#!/bin/bash

echo "[$(date +%s)] generatiing..."
time=$(date +%s)
mkdir nio_perfdiff_$time

~/FlameGraph/stackcollapse-perf.pl $1.unfold > $1.folded
~/FlameGraph/stackcollapse-perf.pl $2.unfold > $2.folded

~/FlameGraph/difffolded.pl -ns $1.folded $2.folded > $1_to_$2_changed.folded
~/FlameGraph/difffolded.pl -ns $2.folded $1.folded > $1_to_$2_will_change.folded

~/FlameGraph/flamegraph.pl $1_to_$2_changed.folded > $1_to_$2_changed.svg
~/FlameGraph/flamegraph.pl --negate $1_to_$2_will_change.folded > $1_to_$2_will_change.svg

mv $1.folded nio_perfdiff_$time
mv $2.folded nio_perfdiff_$time
mv $1_to_$2_changed.* nio_perfdiff_$time
mv $1_to_$2_will_change.* nio_perfdiff_$time

echo "[$(date +%s)] successfully"


