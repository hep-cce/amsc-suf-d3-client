# amsc-suf-d3-client
Repository for client, data, and metrics.


## Benchmarking
The benchmarking is performed with `perf_analyzer`.

```bash
./run_perf_analyzer.sh --host nid001020 \
  --model DoubleMetricLearning \
  --input /global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/gnn4itk_dml_10evts.json \
  --output-dir benchmark_results/gnn4itk_v2 \
  --range 1:4:1 \
  --instances 1 \
  --gpus 1 \
  --measurement-ms 240000
```

%%% --host triton-cluster-svc.ml4phys.com --port 443\

### Nugraph2

```bash
./run_perf_analyzer.sh \
  --model nugraph2 --host nid001257 \
  --input /global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/microbone_nugraph2_100evts.json \
  --output-dir benchmark_results/nugraph2_v1 \
  --range 1:4:1 \
  --instances 1 \
  --gpus 1 \
  --measurement-ms 240000
```

### ATLAS DAOD
`/global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/ATLAS_DAOD/BTagging_network_8085e6c5717c/request_1.json`
`/global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/daod_BTagging_network_8085e6c5717c_31080evts.json`
`/global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/cleaned_daod_BTagging_network_8085e6c5717c_31080evts.json`
```bash
IN_FILE="/global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/cleaned_daod_input.json"
IN_FILE="/global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/cleaned_daod_BTagging_network_8085e6c5717c_31080evts.json"
./run_perf_analyzer.sh \
  --model BTagging_network_8085e6c5717c --host nid004208 \
  --input ${IN_FILE} \
  --output-dir benchmark_results/daod_BTagging_8085e6c5717c_v4 \
  --range 2:20:2 \
  --instances 8 \
  --gpus 0 \
  --measurement-ms 2000
```


## Evaluation

### ATLAS GNN4ITk
Setup ATLAS environment at NERSC
```bash
shifter --image=beojan/mpicuda9-2:latest --module=cvmfs,gpu

export PATH=/cvmfs/sft.cern.ch/lcg/contrib/ninja/1.11.1/Linux-x86_64/bin:$PATH
source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,main,here,latest
```

Run the reconstruction command:
```bash
mkdir inputData
cp /global/cfs/cdirs/atlas/xju/data/inputData/RDO.37737772._000213.pool.root.1 inputData/

RDO_FILENAME="inputData/RDO.37737772._000213.pool.root.1"
AOD_OUTFILE="AOD.37737772._000213.pool.root.1"

TRITON_MODEL_NAME='DoubleMetricLearning'
TRITON_URL=xxxx
TRITON_PORT=8001

export ATHENA_CORE_NUMBER=1

Reco_tf.py --CA 'all:True' \
  --autoConfiguration 'everything' \
  --conditionsTag 'all:OFLCOND-MC15c-SDR-14-05' \
  --geometryVersion 'all:ATLAS-P2-RUN4-03-00-00' \
  --multithreaded 'True' \
  --steering 'doRAWtoALL' \
  --digiSteeringConf 'StandardInTimeOnlyTruth' \
  --postInclude 'all:PyJobTransforms.UseFrontier' \
  --preExec "all:flags.ITk.doEndcapEtaNeighbour=True; flags.Tracking.ITkGNNPass.minClusters = [7,7,7]; flags.Tracking.ITkGNNPass.maxHoles = [4,4,2]; flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\"; flags.Tracking.GNN.Triton.port = ${TRITON_PORT}" \
  --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
  --inputRDOFile="${RDO_FILENAME}" \
  --outputAODFile="OUTFILE" --athenaopts='--loglevel=INFO' --maxEvents 2
```


### ATLAS DAOD data

Setup ATLAS environment at NERSC
```bash
shifter --image=beojan/mpicuda9-2:latest --module=cvmfs,gpu

export PATH=/cvmfs/sft.cern.ch/lcg/contrib/ninja/1.11.1/Linux-x86_64/bin:$PATH
source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,main,here,latest
```

Then run the command:
```bash
export ATHENA_PROC_NUMBER=8
export ATHENA_CORE_NUMBER=8
TRITON_URL="nid004145"
TRITON_PORT=8001
TRITON_SSL=False
IN_DAOD_FILE="/global/homes/x/xju/m3443/data/DAOD_PHYS/data24_13p6TeV.00485051.physics_Main.merge.AOD.f1518_m2248._lb0092._0002.1"

Derivation_tf.py \
  --inputAODFile ${IN_DAOD_FILE} \
  --outputDAODFile test.pool.root \
  --athenaMPMergeTargetSize "DAOD_*:0" \
  --multiprocess True --sharedWriter True \
  --formats PHYS --outputDAODFile 45208950._000004.pool.root.1 \
  --multithreadedFileValidation True \
  --CA "all:True" \
  --parallelCompression False \
  --perfmon fullmonmt \
  --postExec "NNSharingSvc=cfg.getService('FTagNNSharingSvc');NNSharingSvc.UseTriton=True;NNSharingSvc.TritonUrl=\"${TRITON_URL}\";NNSharingSvc.TritonPort=${TRITON_PORT};NNSharingSvc.TritonUseSSL=${TRITON_SSL}"
```
