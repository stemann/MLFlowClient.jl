"""
    MLFlowRunStatus

Represents the status of an MLFlow Run.

# Fields
- `status::String`: one of RUNNING/SCHEDULED/FINISHED/FAILED/KILLED

# Constructors

- `MLFlowRunStatus(status::String)`
"""
struct MLFlowRunStatus
    status::String
    function MLFlowRunStatus(status::String)
        acceptable_statuses = ["RUNNING", "SCHEDULED", "FINISHED", "FAILED", "KILLED"]
        status ∈ acceptable_statuses || error("Invalid status $status - choose one of $acceptable_statuses")
        new(status)
    end
end
Base.show(io::IO, t::MLFlowRunStatus) = show(io, ShowCase(t, new_lines=true))

"""
    MLFlowRunInfo

Represents run metadata.

# Fields
- `run_id::String`: run identifier.
- `experiment_id::Integer`: experiment identifier.
- `status::MLFlowRunStatus`: run status.
- `run_name::String`: run name.
- `start_time::Union{Int64,Missing}`: when was the run started, UNIX time in milliseconds.
- `end_time::Union{Int64,Missing}`: when did the run end, UNIX time in milliseconds.
- `artifact_uri::String`: where are artifacts from this run stored.
- `lifecycle_stage::String`: one of `active` or `deleted`.

# Constructors

- `MLFlowRunInfo(run_id, experiment_id, status, run_name, start_time, end_time, artifact_uri, lifecycle_stage)`
- `MLFlowRunInfo(info::Dict{String,Any})`
"""
struct MLFlowRunInfo
    run_id::String
    experiment_id::Integer
    status::MLFlowRunStatus
    run_name::String
    start_time::Union{Int64,Missing}
    end_time::Union{Int64,Missing}
    artifact_uri::String
    lifecycle_stage::String
end
function MLFlowRunInfo(info::Dict{String,Any})
    run_id = get(info, "run_id", missing)
    experiment_id = get(info, "experiment_id", missing)
    status = get(info, "status", missing)
    run_name = get(info, "run_name", missing)
    start_time = get(info, "start_time", missing)
    end_time = get(info, "end_time", missing)
    artifact_uri = get(info, "artifact_uri", "")
    lifecycle_stage = get(info, "lifecycle_stage", "")

    experiment_id = ismissing(experiment_id) ? experiment_id : parse(Int64, experiment_id)
    status = ismissing(status) ? status : MLFlowRunStatus(status)

    # support for mlflow 1.21.0
    if !ismissing(start_time) && !(typeof(start_time) <: Int)
        start_time = parse(Int64, start_time)
    end
    if !ismissing(end_time) && !(typeof(end_time) <: Int)
        end_time = parse(Int64, end_time)
    end
    MLFlowRunInfo(run_id, experiment_id, status, run_name, start_time, end_time, artifact_uri, lifecycle_stage)
end
Base.show(io::IO, t::MLFlowRunInfo) = show(io, ShowCase(t, new_lines=true))
get_run_id(runinfo::MLFlowRunInfo) = runinfo.run_id

"""
    MLFlowRunDataMetric

Represents a metric.

# Fields
- `key::String`: metric identifier.
- `value::Float64`: metric value.
- `step::Int64`: step.
- `timestamp::Int64`: timestamp in UNIX time in milliseconds.

# Constructors

- `MLFlowRunDataMetric(d::Dict{String,Any})`

"""
struct MLFlowRunDataMetric
    key::String
    value::Float64
    step::Int64
    timestamp::Int64
end
function MLFlowRunDataMetric(d::Dict{String,Any})
    key = d["key"]
    value = d["value"]
    if typeof(d["step"]) <: Int
        step = d["step"]
    else
        step = parse(Int64, d["step"])
    end
    if typeof(d["timestamp"]) <: Int
        timestamp = d["timestamp"]
    else
        timestamp = parse(Int64, d["timestamp"])
    end
    MLFlowRunDataMetric(key, value, step, timestamp)
end
Base.show(io::IO, t::MLFlowRunDataMetric) = show(io, ShowCase(t, new_lines=true))

"""
    MLFlowRunDataParam

Represents a parameter.

# Fields
- `key::String`: parameter identifier.
- `value::String`: parameter value.

# Constructors
- `MLFlowRunDataParam(d::Dict{String,String})`

"""

struct MLFlowRunDataParam
    key::String
    value::String
end
function MLFlowRunDataParam(d::Dict{String,String})
    key = d["key"]
    value = d["value"]
    MLFlowRunDataParam(key, value)
end
Base.show(io::IO, t::MLFlowRunDataParam) = show(io, ShowCase(t, new_lines=true))

"""
    MLFlowRunData

Represents run data.

# Fields
- `metrics::Dict{String,MLFlowRunDataMetric}`: run metrics.
- `params::Dict{String,MLFlowRunDataParam}`: run parameters.
- `tags`: list of run tags.

# Constructors

- `MLFlowRunData(data::Dict{String,Any})`

"""
struct MLFlowRunData
    metrics::Dict{String,MLFlowRunDataMetric}
    params::Union{Dict{String,MLFlowRunDataParam},Missing}
    tags
end
function MLFlowRunData(data::Dict{String,Any})
    metrics = Dict{String,MLFlowRunDataMetric}()
    if haskey(data, "metrics")
        for metric in data["metrics"]
            new_metric = MLFlowRunDataMetric(metric)
            metrics[new_metric.key] = new_metric
        end
    end
    params = Dict{String,MLFlowRunDataParam}()
    if haskey(data, "params")
        for param in data["params"]
            new_param = MLFlowRunDataParam(param["key"], param["value"])
            params[new_param.key] = new_param
        end
    end
    tags = haskey(data, "tags") ? data["tags"] : missing
    MLFlowRunData(metrics, params, tags)
end
Base.show(io::IO, t::MLFlowRunData) = show(io, ShowCase(t, new_lines=true))
get_params(rundata::MLFlowRunData) = rundata.params

"""
    MLFlowRun

Represents an MLFlow run.

# Fields
- `info::MLFlowRunInfo`: Run metadata.
- `data::MLFlowRunData`: Run data.

# Constructors

- `MLFlowRun(rundata::MLFlowRunData)`
- `MLFlowRun(runinfo::MLFlowRunInfo)`
- `MLFlowRun(info::Dict{String,Any})`
- `MLFlowRun(info::Dict{String,Any}, data::Dict{String,Any})`

"""
struct MLFlowRun
    info::Union{MLFlowRunInfo,Missing}
    data::Union{MLFlowRunData,Missing}
end
MLFlowRun(rundata::MLFlowRunData) =
    MLFlowRun(missing, rundata)
MLFlowRun(runinfo::MLFlowRunInfo) =
    MLFlowRun(runinfo, missing)
MLFlowRun(info::Dict{String,Any}) =
    MLFlowRun(MLFlowRunInfo(info), missing)
MLFlowRun(info::Dict{String,Any}, data::Dict{String,Any}) =
    MLFlowRun(MLFlowRunInfo(info), MLFlowRunData(data))
Base.show(io::IO, t::MLFlowRun) = show(io, ShowCase(t, new_lines=true))
get_info(run::MLFlowRun) = run.info
get_data(run::MLFlowRun) = run.data
get_run_id(run::MLFlowRun) = get_run_id(run.info)
get_params(run::MLFlowRun) = get_params(run.data)
