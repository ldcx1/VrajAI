---
name: ML Experimentation
description: How to orchestrate and run complex ML experiments on the Nomad cluster.
---

# ML Experimentation

Running large scale operations, evaluations, or model-training requires deliberate resource allocation and task delegation. You have privileged permissions to orchestrate heavy payloads, but you must do so safely.

## Experimentation Principles
1. **Never block the terminal**: Do not run massive ML loops natively inside your immediate bash terminal. It will lock up your environment.
2. **The Shared Directory**: Write your evaluation scripts to the `/experiments` volume (mapped to the host `experiments_data`).
3. **Isolated Environments**: Always create a distinct Python Virtual Environment for your experiment to prevent dependency corruption.
4. **The Runner**: Use the `celery-mcp` service to asynchronously queue and run the script inside `/experiments` across the cluster nodes. Always invoke the script using the dedicated environment's python binary.
5. **Telemetry**: Always check Prometheus before launching tests to ensure `node_gpu_utilization` and memory can handle the impending payload.

## Example: Multi-GPU PyTorch DDP Experiment

If you are asked to validate models via multi-GPU inference or training, write generic PyTorch Distributed Data Parallel (DDP) wrappers.

1. **Write the Script** (`/experiments/multi_gpu_test.py`):
```python
import os
import torch
import torch.distributed as dist
import torch.nn as nn
import torch.optim as optim
from torch.nn.parallel import DistributedDataParallel as DDP

def setup(rank, world_size):
    os.environ['MASTER_ADDR'] = 'localhost'
    os.environ['MASTER_PORT'] = '12355'
    dist.init_process_group("nccl", rank=rank, world_size=world_size)

def cleanup():
    dist.destroy_process_group()

def demo_basic(rank, world_size):
    setup(rank, world_size)
    print(f"Running DDP process on rank {rank}.")

    # create model and move it to GPU with id rank
    model = nn.Linear(10, 10).to(rank)
    ddp_model = DDP(model, device_ids=[rank])

    loss_fn = nn.MSELoss()
    optimizer = optim.SGD(ddp_model.parameters(), lr=0.001)

    # Forward pass
    outputs = ddp_model(torch.randn(20, 10).to(rank))
    labels = torch.randn(20, 10).to(rank)
    
    # Backward pass and optimize
    loss_fn(outputs, labels).backward()
    optimizer.step()
    
    print(f"Rank {rank} completed optimization step.")
    cleanup()

def run_demo(demo_fn, world_size):
    import torch.multiprocessing as mp
    mp.spawn(demo_fn, args=(world_size,), nprocs=world_size, join=True)

if __name__ == "__main__":
    n_gpus = torch.cuda.device_count()
    print(f"Detected {n_gpus} GPUs.")
    if n_gpus > 1:
        run_demo(demo_basic, n_gpus)
    else:
        print("Requires at least 2 GPUs to run DDP cleanly.")
```

2. **Setup the Virtual Environment**: Before handing off to Celery, create the isolated requirement map:
```bash
python -m venv /experiments/ddp_test_env
/experiments/ddp_test_env/bin/pip install torch
```

3. **Hand off to Celery**: Once saved to `/experiments` and the environment is built, invoke the celery MCP server to execute using the *absolute path* to the virtual environment's binary:
`/experiments/ddp_test_env/bin/python /experiments/multi_gpu_test.py`.

4. **Evaluate Results**: Read the log artifacts from the `/experiments` trace logs to determine success or failure without locking your own process thread.
