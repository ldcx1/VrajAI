---
name: MLflow Experiment Tracking
description: How to log hyperparameter sweeps, model checkpoints, and evaluation metrics to the central MLflow server.
---

# MLflow Experiment Tracking

When running machine learning evaluations via `celery-mcp` or iterating locally, you must not rely solely on bash `stdout` logs. VrajAI hosts an internal MLflow tracking server that must be used to record results permanently.

## Core Rules

1. **Tracking URI**: Your scripts must point to the MLflow tracking server at `http://127.0.0.1:5000`. This is tunneled through the Consul Service Mesh directly to the MLflow container.
2. **Environment**: Install `mlflow` and `boto3` in your Python virtual environment.
3. **Authentication**: The MLflow container auto-authenticates to MinIO using the AWS keys established via Vault. You do not need to explicitly configure S3 keys inside your Python script when logging MLflow artifacts.

## Example Integration

Wrap your PyTorch or Scikit-Learn training loops with `mlflow.start_run()`.

```python
import mlflow

def run_experiment(learning_rate, epochs):
    # Connect to the mesh-routed tracking server
    mlflow.set_tracking_uri("http://127.0.0.1:5000")
    mlflow.set_experiment("Nanobot-Deep-Learning-Sweep")
    
    with mlflow.start_run():
        mlflow.log_param("learning_rate", learning_rate)
        mlflow.log_param("epochs", epochs)
        
        # ... training math ...
        final_loss = 0.045
        
        mlflow.log_metric("final_loss", final_loss)
        
        # Save models natively to MLflow (which backs up to MinIO S3)
        # mlflow.pytorch.log_model(model, "model")
        
if __name__ == "__main__":
    run_experiment(0.001, 100)
```
